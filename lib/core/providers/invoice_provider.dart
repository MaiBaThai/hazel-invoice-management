import 'package:flutter/material.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/services/database_service.dart';
import 'customer_provider.dart';

class InvoiceProvider extends ChangeNotifier {
  DatabaseService _dbService;
  CustomerProvider? _customerProvider;

  InvoiceProvider(this._dbService);

  void updateDbService(DatabaseService newService) {
    debugPrint('InvoiceProvider: updateDbService called with userId: ${newService.userId}');
    _dbService = newService;
    reset(); // Clear local state when user identity potentially changes
  }

  void updateCustomerProvider(CustomerProvider customerProvider) {
    _customerProvider = customerProvider;
  }

  Customer? _selectedCustomer;
  List<ServiceItem> _services = [];
  double _discountPercent = 0;
  bool _isSaving = false;
  int _resetCounter = 0; // Used to force UI refresh

  // Edit state variables
  String? _editingInvoiceId;
  double _originalTotal = 0;
  List<String> _editingPhotoUrls = [];
  DateTime? _editingCreatedAt;
  DateTime? _sessionStart;
  DateTime? _sessionEnd;

  List<Customer> _searchResults = [];
  bool _isSearching = false;

  Customer? get selectedCustomer => _selectedCustomer;
  List<ServiceItem> get services => _services;
  double get discountPercent => _discountPercent;
  bool get isSaving => _isSaving;
  bool get hasLoadedCustomers => _customerProvider?.allCustomers.isNotEmpty ?? false;
  int get resetCounter => _resetCounter;
  bool get isEditing => _editingInvoiceId != null;
  List<Customer> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  DateTime? get sessionStart => _sessionStart;
  DateTime? get sessionEnd => _sessionEnd;

  // Improved helper to remove Vietnamese diacritics without corrupting the string
  String _normalizeAndRemoveDiacritics(String str) {
    if (str.isEmpty) return '';
    
    var result = str.toLowerCase();
    
    // 1. Map common precomposed Vietnamese characters to their base letters
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
    
    // 2. Explicitly strip ANY remaining combining marks (crucial for NFD/Mac/iOS)
    // This removes the invisible accent characters that cause comparison failures
    result = result.replaceAll(RegExp(r'[\u0300-\u036f]'), '');
    
    return result;
  }

  // Search Logic
  Future<void> searchCustomers(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    
    _isSearching = true;
    notifyListeners();
    
    try {
      final allCustomers = _customerProvider?.allCustomers ?? [];
      final lowerQuery = trimmedQuery.toLowerCase();
      final normalizedQuery = _normalizeAndRemoveDiacritics(lowerQuery);
      
      _searchResults = allCustomers.where((customer) {
        final nameLower = customer.name.toLowerCase();
        final normalizedName = _normalizeAndRemoveDiacritics(nameLower);
        final phoneMatch = customer.phone.contains(trimmedQuery);
        
        // Match original name OR normalized name OR phone
        return nameLower.contains(lowerQuery) || 
               normalizedName.contains(normalizedQuery) ||
               phoneMatch;
      }).toList();

      // Sort results: prefix matches first
      _searchResults.sort((a, b) {
        final aName = a.name.toLowerCase();
        final bName = b.name.toLowerCase();
        final aStarts = aName.startsWith(lowerQuery);
        final bStarts = bName.startsWith(lowerQuery);
        
        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;
        return aName.compareTo(bName);
      });
      
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  // Fallback: Manually show all customers if search fails
  void showAllCustomers() async {
    _isSearching = true;
    notifyListeners();
    try {
      final allCustomers = _customerProvider?.allCustomers ?? [];
      _searchResults = List.from(allCustomers);
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> createNewCustomer(BuildContext context, String name, String phone) async {
    try {
      final customer = Customer(id: '', name: name, phone: phone);
      
      // Use a timeout to prevent infinite hang if Firestore permissions fail
      final id = await _dbService.addCustomer(customer).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Connection timeout. Please check your internet or permissions.'),
      );
      
      final newCustomer = customer.copyWith(id: id);
      _selectedCustomer = newCustomer;
      
      // Add to shared cache so it's searchable immediately across all screens
      _customerProvider?.addCustomerLocally(newCustomer);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating customer: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating customer: $e'), backgroundColor: Colors.red),
        );
      }
      rethrow;
    }
  }

  // Calculations
  double get subtotal => _services.fold(0, (sum, item) => sum + item.price);
  double get finalTotal => subtotal * (1 - _discountPercent / 100);

  // Setters
  void selectCustomer(Customer? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void setSessionRange(DateTime? start, DateTime? end) {
    _sessionStart = start;
    _sessionEnd = end;
    notifyListeners();
  }

  void addService() {
    _services.add(ServiceItem(serviceName: '', price: 0));
    notifyListeners();
  }

  void removeService(int index) {
    if (_services.isNotEmpty && index >= 0 && index < _services.length) {
      _services.removeAt(index);
      notifyListeners();
    }
  }

  void updateService(int index, String name, double price) {
    _services[index] = ServiceItem(serviceName: name, price: price);
    notifyListeners();
  }

  void setDiscount(double percent) {
    _discountPercent = percent;
    notifyListeners();
  }

  void loadInvoiceForEditing(Invoice invoice, Customer customer) {
    _editingInvoiceId = invoice.id;
    _originalTotal = invoice.finalTotal;
    _editingPhotoUrls = List.from(invoice.photoUrls);
    _editingCreatedAt = invoice.createdAt;

    _selectedCustomer = customer;
    _services = List.from(invoice.services);
    _discountPercent = invoice.discountPercent;
    _sessionStart = invoice.sessionStart;
    _sessionEnd = invoice.sessionEnd;
    
    notifyListeners();
  }

  // Action
  Future<String?> saveInvoice(BuildContext context) async {
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer')),
      );
      return null;
    }

    if (subtotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice must have at least one service')),
      );
      return null;
    }

    if (_editingInvoiceId == null && (_sessionStart == null || _sessionEnd == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select session date & time')),
      );
      return null;
    }

    _isSaving = true;
    notifyListeners();

    try {
      final invoice = Invoice(
        id: _editingInvoiceId ?? '',
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.name,
        services: _services.where((s) => s.serviceName.isNotEmpty).toList(),
        subtotal: subtotal,
        discountPercent: _discountPercent,
        finalTotal: finalTotal,
        photoUrls: _editingInvoiceId != null ? _editingPhotoUrls : [],
        createdAt: _editingCreatedAt ?? DateTime.now(),
        sessionStart: _sessionStart,
        sessionEnd: _sessionEnd,
      );

      String? invoiceId;
      if (_editingInvoiceId != null) {
        await _dbService.updateInvoice(_editingInvoiceId!, invoice, _originalTotal);
        invoiceId = _editingInvoiceId;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoice updated successfully!')),
          );
        }
      } else {
        invoiceId = await _dbService.saveInvoice(invoice);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoice saved successfully!')),
          );
        }
      }
      return invoiceId;
    } catch (e) {
      if (context.mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('Exception: ')) {
          errorMessage = errorMessage.replaceFirst('Exception: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void reset() {
    _selectedCustomer = null;
    _services = [];
    _discountPercent = 0;
    _searchResults = [];
    _editingInvoiceId = null;
    _originalTotal = 0;
    _editingPhotoUrls = [];
    _editingCreatedAt = null;
    _sessionStart = null;
    _sessionEnd = null;
    _resetCounter++;
    notifyListeners();
  }

  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }
}
