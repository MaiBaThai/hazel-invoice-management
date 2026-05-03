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
      bankName: map['bank_name'] ?? 'MB Bank',
      accountNumber: map['account_number'] ?? '0902994602',
      accountName: map['account_name'] ?? 'VO THI BICH BAO',
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
        bankName: 'MB Bank',
        accountNumber: '0902994602',
        accountName: 'VO THI BICH BAO',
      ),
      predefinedServices: [
        ServiceItem(serviceName: 'Cắt da', price: 50.0),
        ServiceItem(serviceName: 'Sơn Gel', price: 100.0),
        ServiceItem(serviceName: 'Úp móng', price: 150.0),
        ServiceItem(serviceName: 'Đắp Gel', price: 200.0),
      ],
    );
  }
}
