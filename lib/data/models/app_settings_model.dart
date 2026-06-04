import 'package:nms/data/models/invoice_model.dart';

class BusinessConfig {
  final String businessName;
  final String currencySymbol; // 'k' or '$'

  BusinessConfig({
    required this.businessName,
    required this.currencySymbol,
  });

  bool get isPrefix => currencySymbol == '\$';
  bool get enableVietQR => currencySymbol == 'k';

  factory BusinessConfig.fromMap(Map<String, dynamic> map) {
    return BusinessConfig(
      businessName: map['business_name'] ?? 'My Salon',
      currencySymbol: map['currency_symbol'] ?? '\$',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'business_name': businessName,
      'currency_symbol': currencySymbol,
    };
  }
}

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
  final BusinessConfig businessConfig;
  final BankConfig bankConfig;
  final List<ServiceItem> predefinedServices;

  AppSettings({
    required this.businessConfig,
    required this.bankConfig,
    required this.predefinedServices,
  });

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      businessConfig: BusinessConfig.fromMap(map['business_config'] ?? {}),
      bankConfig: BankConfig.fromMap(map['bank_config'] ?? {}),
      predefinedServices: (map['predefined_services'] as List? ?? [])
          .map((s) => ServiceItem.fromMap(s as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'business_config': businessConfig.toMap(),
      'bank_config': bankConfig.toMap(),
      'predefined_services': predefinedServices.map((s) => s.toMap()).toList(),
    };
  }

  // Default empty settings if document doesn't exist yet
  factory AppSettings.defaultSettings() {
    return AppSettings(
      businessConfig: BusinessConfig(
        businessName: 'My Salon',
        currencySymbol: '\$',
      ),
      bankConfig: BankConfig(
        bankName: '',
        accountNumber: '',
        accountName: '',
      ),
      predefinedServices: [],
    );
  }
}
