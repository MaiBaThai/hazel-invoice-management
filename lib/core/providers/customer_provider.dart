import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/services/database_service.dart';

class CustomerProvider extends ChangeNotifier {
  DatabaseService _dbService;
  final ImagePicker _picker = ImagePicker();

  CustomerProvider(this._dbService);

  void updateDbService(DatabaseService newService) {
    debugPrint('CustomerProvider: updateDbService called with userId: ${newService.userId}');
    _dbService = newService;
    _allCustomers = [];
    _searchResults = [];
    _selectedCustomer = null;
    _customerInvoices = [];
    
    // Only load if we have a valid userId
    if (newService.userId != null) {
      loadCustomers();
    } else {
      notifyListeners(); // Ensure UI knows we are empty
    }
  }

  List<Customer> _allCustomers = [];
  List<Customer> _searchResults = [];
  bool _isLoading = false;
  final bool _isSearching = false;

  Customer? _selectedCustomer;
  List<Invoice> _customerInvoices = [];
  bool _isLoadingDetails = false;
  bool _isUploadingPhoto = false;
  String? _uploadError;

  // Getters
  List<Customer> get allCustomers => _allCustomers;
  List<Customer> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  Customer? get selectedCustomer => _selectedCustomer;
  List<Invoice> get customerInvoices => _customerInvoices;
  bool get isLoadingDetails => _isLoadingDetails;
  bool get isUploadingPhoto => _isUploadingPhoto;
  String? get uploadError => _uploadError;

  Future<void> loadCustomers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allCustomers = await _dbService.getCustomers();
      _searchResults = [];
    } catch (e) {
      debugPrint('Error loading customers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _normalizeAndRemoveDiacritics(String str) {
    if (str.isEmpty) return '';
    var result = str.toLowerCase();
    var map = {
      'a': RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'),
      'e': RegExp(r'[èéẹẻẽêềếệểễ]'),
      'i': RegExp(r'[ìíịỉĩ]'),
      'o': RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'),
      'u': RegExp(r'[ùúụủũưừứựửữ]'),
      'y': RegExp(r'[ỳýỵỷỹ]'),
      'd': RegExp(r'[đ]'),
    };
    map.forEach((key, value) {
      result = result.replaceAll(value, key);
    });
    result = result.replaceAll(RegExp(r'[\u0300-\u036f]'), '');
    return result;
  }

  void searchCustomers(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    final lowerQuery = trimmedQuery.toLowerCase();
    final normalizedQuery = _normalizeAndRemoveDiacritics(lowerQuery);

    _searchResults = _allCustomers.where((customer) {
      final nameLower = customer.name.toLowerCase();
      final normalizedName = _normalizeAndRemoveDiacritics(nameLower);
      final phoneMatch = customer.phone.contains(trimmedQuery);
      return nameLower.contains(lowerQuery) || 
             normalizedName.contains(normalizedQuery) ||
             phoneMatch;
    }).toList();

    notifyListeners();
  }

  Future<void> loadCustomerDetails(String customerId) async {
    _isLoadingDetails = true;
    notifyListeners();
    try {
      _selectedCustomer = await _dbService.getCustomer(customerId);
      if (_selectedCustomer != null) {
        _customerInvoices = await _dbService.getCustomerInvoices(customerId);
      }
    } catch (e) {
      debugPrint('Error loading customer details: $e');
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }

  Future<void> deleteCustomer(String customerId) async {
    try {
      // 1. Load details to get all photo URLs if any
      final invoices = await _dbService.getCustomerInvoices(customerId);
      for (var invoice in invoices) {
        for (var url in invoice.photoUrls) {
          await _dbService.deletePhoto(url);
        }
      }
      
      // 2. Delete from DB
      await _dbService.deleteCustomer(customerId);
      
      // 3. Update local state
      _allCustomers.removeWhere((c) => c.id == customerId);
      _searchResults.removeWhere((c) => c.id == customerId);
      if (_selectedCustomer?.id == customerId) _selectedCustomer = null;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting customer: $e');
    }
  }

  // --- Photo Logic ---

  Future<void> uploadPhotoForInvoice(String invoiceId, String customerId) async {
    _isUploadingPhoto = true;
    _uploadError = null;
    notifyListeners();
    
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 70,
      );

      if (image == null) {
        _isUploadingPhoto = false;
        notifyListeners();
        return;
      }

      Uint8List bytes = await image.readAsBytes();
      debugPrint('Original size: ${bytes.length} bytes');
      
      // Only compress if image is large (> 200KB)
      if (bytes.length > 200 * 1024) {
        try {
          final img.Image? originalImage = img.decodeImage(bytes);
          if (originalImage != null) {
            img.Image resizedImage;
            if (originalImage.width > originalImage.height) {
              resizedImage = img.copyResize(originalImage, width: 1080);
            } else {
              resizedImage = img.copyResize(originalImage, height: 1080);
            }
            bytes = Uint8List.fromList(img.encodeJpg(resizedImage, quality: 70));
            debugPrint('Compressed to: ${bytes.length} bytes');
          }
        } catch (e) {
          debugPrint('Compression failed, using original: $e');
        }
      }

      // Add a timeout to the upload process
      final url = await _dbService.uploadInvoicePhoto(invoiceId, customerId, bytes)
          .timeout(const Duration(seconds: 30), onTimeout: () {
            throw Exception('Upload timed out. Please check your internet and Firebase Storage rules.');
          });
          
      await _dbService.updateInvoicePhotos(invoiceId, [url]);
      
      debugPrint('Upload success: $url');
      await loadCustomerDetails(customerId);
    } catch (e) {
      _uploadError = e.toString();
      debugPrint('Error uploading photo: $e');
    } finally {
      _isUploadingPhoto = false;
      notifyListeners();
    }
  }

  Future<void> updateCustomer(String id, String name, String phone) async {
    try {
      await _dbService.updateCustomer(id, name, phone);
      await loadCustomerDetails(id);
    } catch (e) {
      debugPrint('Error updating customer: $e');
      rethrow;
    }
  }

  Future<void> deletePhoto(String invoiceId, String customerId, String photoUrl) async {
    try {
      await _dbService.deleteInvoicePhoto(invoiceId, photoUrl);
      await loadCustomerDetails(customerId);
    } catch (e) {
      debugPrint('Error deleting photo: $e');
      rethrow;
    }
  }
}
