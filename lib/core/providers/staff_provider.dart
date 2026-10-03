import 'package:flutter/material.dart';
import '../../data/models/staff_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/services/database_service.dart';

class StaffProvider extends ChangeNotifier {
  DatabaseService _dbService;

  StaffProvider(this._dbService);

  void updateDbService(DatabaseService newService) {
    if (_dbService.userId == newService.userId && _hasLoadedOnce) {
      _dbService = newService;
      return;
    }
    debugPrint('StaffProvider: updateDbService called with userId: ${newService.userId}');
    _dbService = newService;
    _allStaff = [];
    _searchResults = [];
    _selectedStaff = null;
    _staffInvoices = [];
    _hasLoadedOnce = false;
    _hasError = false;

    if (newService.userId != null) {
      loadStaff();
    } else {
      _hasLoadedOnce = true;
      notifyListeners();
    }
  }

  List<Staff> _allStaff = [];
  List<Staff> _searchResults = [];
  bool _isLoading = false;
  bool _hasLoadedOnce = false;
  bool _hasError = false;

  Staff? _selectedStaff;
  List<Invoice> _staffInvoices = [];
  bool _isLoadingDetails = false;

  // Getters
  List<Staff> get allStaff => _allStaff;
  List<Staff> get activeStaff => _allStaff.where((s) => s.isActive).toList();
  List<Staff> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get hasLoadedOnce => _hasLoadedOnce;
  bool get hasError => _hasError;
  Staff? get selectedStaff => _selectedStaff;
  List<Invoice> get staffInvoices => _staffInvoices;
  bool get isLoadingDetails => _isLoadingDetails;

  // Computed metrics for currently selected staff
  double get staffTotalCommission {
    if (_selectedStaff == null) return 0.0;
    final staffName = _selectedStaff!.name;
    double sum = 0.0;

    for (var inv in _staffInvoices) {
      if (inv.staffNames.contains(staffName)) {
        final staffCount = inv.staffNames.isEmpty ? 1 : inv.staffNames.length;
        final commissionable = inv.subtotal * (1 - inv.discountPercent / 100);
        final totalComm = commissionable * (inv.commissionPercent / 100);
        sum += totalComm / staffCount;
      }
    }
    return sum;
  }

  double get staffTotalTips {
    if (_selectedStaff == null) return 0.0;
    final staffName = _selectedStaff!.name;
    double sum = 0.0;

    for (var inv in _staffInvoices) {
      if (inv.staffNames.contains(staffName)) {
        final staffCount = inv.staffNames.isEmpty ? 1 : inv.staffNames.length;
        sum += inv.tip / staffCount;
      }
    }
    return sum;
  }

  double get staffTotalEarnings => staffTotalCommission + staffTotalTips;

  Future<void> loadStaff({bool force = false, bool showLoader = true}) async {
    if (_hasLoadedOnce && !force) {
      return;
    }
    if (showLoader) {
      _isLoading = true;
      _hasError = false;
      notifyListeners();
    }
    try {
      _allStaff = await _dbService.getStaffList().timeout(const Duration(seconds: 5));
      _searchResults = [];
      _hasLoadedOnce = true;
    } catch (e) {
      debugPrint('Error loading staff: $e');
      if (showLoader) {
        _hasError = true;
      }
    } finally {
      if (showLoader) {
        _isLoading = false;
      }
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

  void searchStaff(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    final lowerQuery = trimmedQuery.toLowerCase();
    final normalizedQuery = _normalizeAndRemoveDiacritics(lowerQuery);

    _searchResults = _allStaff.where((staff) {
      final nameLower = staff.name.toLowerCase();
      final normalizedName = _normalizeAndRemoveDiacritics(nameLower);
      final phoneMatch = staff.phone.contains(trimmedQuery);
      return nameLower.contains(lowerQuery) ||
          normalizedName.contains(normalizedQuery) ||
          phoneMatch;
    }).toList();

    notifyListeners();
  }

  Future<void> loadStaffDetails(String staffId) async {
    _isLoadingDetails = true;
    notifyListeners();

    try {
      final staff = await _dbService.getStaff(staffId);
      _selectedStaff = staff;

      if (staff != null) {
        _staffInvoices = await _dbService.getStaffInvoices(staff.name);
      } else {
        _staffInvoices = [];
      }
    } catch (e) {
      debugPrint('Error loading staff details: $e');
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }

  Future<String?> addStaff({
    required String name,
    required String phone,
    double defaultCommissionPercent = 0.0,
  }) async {
    try {
      final newStaff = Staff(
        id: '',
        name: name,
        phone: phone,
        defaultCommissionPercent: defaultCommissionPercent,
        createdAt: DateTime.now(),
        isActive: true,
      );

      final id = await _dbService.addStaff(newStaff);
      final createdStaff = newStaff.copyWith(id: id);
      _allStaff.add(createdStaff);
      _allStaff.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      notifyListeners();
      return id;
    } catch (e) {
      debugPrint('Error adding staff: $e');
      rethrow;
    }
  }

  Future<void> updateStaff(Staff updatedStaff) async {
    try {
      await _dbService.updateStaff(updatedStaff);
      final index = _allStaff.indexWhere((s) => s.id == updatedStaff.id);
      if (index != -1) {
        _allStaff[index] = updatedStaff;
      }
      if (_selectedStaff?.id == updatedStaff.id) {
        _selectedStaff = updatedStaff;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating staff: $e');
      rethrow;
    }
  }

  Future<void> toggleStaffStatus(Staff staff) async {
    final updated = staff.copyWith(isActive: !staff.isActive);
    await updateStaff(updated);
  }

  Future<void> deleteStaff(String staffId) async {
    try {
      await _dbService.deleteStaff(staffId);
      _allStaff.removeWhere((s) => s.id == staffId);
      _searchResults.removeWhere((s) => s.id == staffId);
      if (_selectedStaff?.id == staffId) {
        _selectedStaff = null;
        _staffInvoices = [];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting staff: $e');
      rethrow;
    }
  }
}
