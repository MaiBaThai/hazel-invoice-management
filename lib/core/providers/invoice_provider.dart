import 'package:flutter/material.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/services/database_service.dart';

class InvoiceProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  Customer? _selectedCustomer;
  List<ServiceItem> _services = [];
  double _discountPercent = 0;
  bool _isSaving = false;
  int _resetCounter = 0; // Used to force UI refresh

  List<Customer> _searchResults = [];
  bool _isSearching = false;
  
  List<Customer> _allCustomers = [];
  bool _hasLoadedCustomers = false;

  Future<void> _ensureCustomersLoaded() async {
    if (!_hasLoadedCustomers) {
      _allCustomers = await _dbService.getCustomers();
      _hasLoadedCustomers = true;
    }
  }

  Customer? get selectedCustomer => _selectedCustomer;
  List<ServiceItem> get services => _services;
  double get discountPercent => _discountPercent;
  bool get isSaving => _isSaving;
  int get resetCounter => _resetCounter;
  List<Customer> get searchResults => _searchResults;
  bool get isSearching => _isSearching;

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
      await _ensureCustomersLoaded();
      
      final lowerQuery = trimmedQuery.toLowerCase();
      final normalizedQuery = _normalizeAndRemoveDiacritics(lowerQuery);
      
      _searchResults = _allCustomers.where((customer) {
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
      await _ensureCustomersLoaded();
      _searchResults = List.from(_allCustomers);
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> createNewCustomer(String name, String phone) async {
    final customer = Customer(id: '', name: name, phone: phone);
    final id = await _dbService.addCustomer(customer);
    final newCustomer = customer.copyWith(id: id);
    _selectedCustomer = newCustomer;
    
    // Add to cache so it's searchable immediately
    _allCustomers.add(newCustomer);
    
    notifyListeners();
  }

  // Calculations
  double get subtotal => _services.fold(0, (sum, item) => sum + item.price);
  double get finalTotal => subtotal * (1 - _discountPercent / 100);

  // Setters
  void selectCustomer(Customer? customer) {
    _selectedCustomer = customer;
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

    _isSaving = true;
    notifyListeners();

    try {
      final invoice = Invoice(
        id: '',
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.name,
        services: _services.where((s) => s.serviceName.isNotEmpty).toList(),
        subtotal: subtotal,
        discountPercent: _discountPercent,
        finalTotal: finalTotal,
        photoUrls: [],
        createdAt: DateTime.now(),
      );

      final invoiceId = await _dbService.saveInvoice(invoice);
      
      // We don't reset() immediately here because we might need _selectedCustomer for the photo upload popup
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice saved successfully!')),
        );
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
    _hasLoadedCustomers = false; // Reset cache to get fresh data on next search
    _resetCounter++;
    notifyListeners();
  }

  void clearSearchResults() {
    _searchResults = [];
    _hasLoadedCustomers = false; // Reset cache for fresh data
    notifyListeners();
  }
}
