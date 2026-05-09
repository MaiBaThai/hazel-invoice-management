import 'package:flutter/material.dart';
import '../../data/models/app_settings_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/services/database_service.dart';

class SettingsProvider extends ChangeNotifier {
  DatabaseService _dbService;
  SettingsProvider(this._dbService);

  void updateDbService(DatabaseService newService) {
    _dbService = newService;
    loadSettings();
  }

  AppSettings? _settings;
  bool _isLoading = false;

  AppSettings? get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> loadSettings() async {
    // If we don't have a userId yet, we might want to wait or use defaults
    // In our case, DatabaseService handles null userId by looking at global configs.
    // But to avoid hanging, we'll add a check.
    
    _isLoading = true;
    notifyListeners();

    try {
      // Add a small timeout or check if we should even try
      _settings = await _dbService.getSettings();
    } catch (e) {
      debugPrint('Error loading settings: $e');
      // If it fails, we fall back to default settings so the UI doesn't hang
      _settings ??= AppSettings.defaultSettings();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateBankConfig(BankConfig config) async {
    if (_settings == null) return;
    
    _settings = AppSettings(
      bankConfig: config,
      predefinedServices: _settings!.predefinedServices,
    );
    notifyListeners();
    
    await _dbService.updateSettings(_settings!);
  }

  Future<void> addService(ServiceItem service) async {
    if (_settings == null) return;
    
    final updatedServices = List<ServiceItem>.from(_settings!.predefinedServices)..add(service);
    _settings = AppSettings(
      bankConfig: _settings!.bankConfig,
      predefinedServices: updatedServices,
    );
    notifyListeners();
    
    await _dbService.updateSettings(_settings!);
  }

  Future<void> updateService(int index, ServiceItem service) async {
    if (_settings == null) return;
    
    final updatedServices = List<ServiceItem>.from(_settings!.predefinedServices);
    if (index >= 0 && index < updatedServices.length) {
      updatedServices[index] = service;
      _settings = AppSettings(
        bankConfig: _settings!.bankConfig,
        predefinedServices: updatedServices,
      );
      notifyListeners();
      
      await _dbService.updateSettings(_settings!);
    }
  }

  Future<void> deleteService(int index) async {
    if (_settings == null) return;
    
    final updatedServices = List<ServiceItem>.from(_settings!.predefinedServices);
    if (index >= 0 && index < updatedServices.length) {
      updatedServices.removeAt(index);
      _settings = AppSettings(
        bankConfig: _settings!.bankConfig,
        predefinedServices: updatedServices,
      );
      notifyListeners();
      
      await _dbService.updateSettings(_settings!);
    }
  }
}
