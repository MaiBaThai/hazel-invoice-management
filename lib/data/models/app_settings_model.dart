import 'package:nms/data/models/invoice_model.dart';

class BankConfig {
  final String bankName;
  final String accountNumber;
  final String accountName;

  BankConfig({
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
  });

  factory BankConfig.fromMap(Map<String, dynamic> map) {
    return BankConfig(
      bankName: map['bank_name'] ?? '',
      accountNumber: map['account_number'] ?? '',
      accountName: map['account_name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bank_name': bankName,
      'account_number': accountNumber,
      'account_name': accountName,
    };
  }
}

class AppSettings {
  final BankConfig bankConfig;
  final List<ServiceItem> predefinedServices;

  AppSettings({
    required this.bankConfig,
    required this.predefinedServices,
  });

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      bankConfig: BankConfig.fromMap(map['bank_config'] ?? {}),
      predefinedServices: (map['predefined_services'] as List? ?? [])
          .map((s) => ServiceItem.fromMap(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bank_config': bankConfig.toMap(),
      'predefined_services': predefinedServices.map((s) => s.toMap()).toList(),
    };
  }

  // Default empty settings if document doesn't exist yet
  factory AppSettings.defaultSettings() {
    return AppSettings(
      bankConfig: BankConfig(
        bankName: '',
        accountNumber: '',
        accountName: '',
      ),
      predefinedServices: [],
    );
  }
}
