class SystemConfig {
  final bool subscriptionEnabled;
  final String activeOfferingId;
  final int freeInvoiceLimit;
  final String revenueCatIosApiKey;

  SystemConfig({
    required this.subscriptionEnabled,
    required this.activeOfferingId,
    required this.freeInvoiceLimit,
    required this.revenueCatIosApiKey,
  });

  factory SystemConfig.fromMap(Map<String, dynamic> map) {
    return SystemConfig(
      subscriptionEnabled: map['subscription_enabled'] ?? true,
      activeOfferingId: map['active_offering_id'] ?? 'default',
      freeInvoiceLimit: map['free_invoice_limit'] ?? 50,
      revenueCatIosApiKey: map['revenuecat_ios_api_key'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subscription_enabled': subscriptionEnabled,
      'active_offering_id': activeOfferingId,
      'free_invoice_limit': freeInvoiceLimit,
      'revenuecat_ios_api_key': revenueCatIosApiKey,
    };
  }

  factory SystemConfig.defaultConfig() {
    return SystemConfig(
      subscriptionEnabled: true,
      activeOfferingId: 'default',
      freeInvoiceLimit: 50,
      revenueCatIosApiKey: '',
    );
  }
}
