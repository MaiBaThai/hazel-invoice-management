import 'package:flutter/material.dart';
import '../../data/models/app_settings_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/services/database_service.dart';

class SettingsProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  AppSettings? _settings;
  bool _isLoading = false;

  AppSettings? get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _settings = await _dbService.getSettings();
    } catch (e) {
      debugPrint('Error loading settings: $e');
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
