import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../data/models/system_config_model.dart';
import '../../data/services/database_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  DatabaseService _dbService;

  // Streams/Subscriptions
  StreamSubscription? _configSubscription;
  StreamSubscription? _whitelistSubscription;
  StreamSubscription? _authSubscription;

  // State
  SystemConfig _systemConfig = SystemConfig.defaultConfig();
  List<String> _whitelistedEmails = [];
  bool _isPremium = false;
  bool _isLoading = true;
  bool _isProcessingPurchase = false;
  Offerings? _offerings;
  CustomerInfo? _customerInfo;
  String? _lastError = "Waiting for Firestore config...";

  String? get lastError => _lastError;
  bool get isProcessingPurchase => _isProcessingPurchase;

  // RevenueCat iOS API Key placeholder (can be overwritten remotely via Firestore config)
  static const String _defaultRcApiKey = "appl_afLPLQmZIcStGpGkcZbwtNwuCfa"; 
  String _rcApiKey = _defaultRcApiKey;
  bool _rcConfigured = false;
  String? _configuredApiKey;
  bool _isConfiguring = false;
  bool _isLoadingOfferings = false;
  final FirebaseAuth _auth;

  SubscriptionProvider(this._dbService, {FirebaseAuth? auth}) 
      : _auth = auth ?? FirebaseAuth.instance {
    _initAuthListener();
    _startFirestoreListeners();
  }

  void updateDbService(DatabaseService newService) {
    final oldUserId = _dbService.userId;
    _dbService = newService;

    if (oldUserId != newService.userId) {
      debugPrint('SubscriptionProvider: User ID changed from $oldUserId to ${newService.userId}');
      // Restart listeners for the new database scope
      _startFirestoreListeners();
      _syncUserWithRevenueCat();
    }
  }

  // Getters
  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  SystemConfig get systemConfig => _systemConfig;
  int get freeInvoiceLimit => _systemConfig.freeInvoiceLimit;
  Offerings? get offerings => _offerings;
  List<Package> get activePackages => 
      _offerings?.all[_systemConfig.activeOfferingId]?.availablePackages ?? 
      _offerings?.current?.availablePackages ?? 
      [];

  // --- Initializers ---

  void _initAuthListener() {
    _authSubscription?.cancel();
    _authSubscription = _auth.userChanges().listen((user) {
      _updatePremiumStatus();
      _syncUserWithRevenueCat();
    });
  }

  void _startFirestoreListeners() {
    _configSubscription?.cancel();
    _configSubscription = _dbService.watchSystemConfig().listen(
      (config) {
        _systemConfig = config;
        
        final remoteKey = config.revenueCatIosApiKey;
        final apiKeyToUse = remoteKey.isNotEmpty ? remoteKey : _defaultRcApiKey;

        if (!_rcConfigured || _configuredApiKey != apiKeyToUse) {
          _configureRevenueCat(apiKeyToUse);
        } else {
          _loadOfferings();
        }
        
        _updatePremiumStatus();
      },
      onError: (error) {
        debugPrint("Error watching system config: $error");
        _lastError = "Firestore config error: $error";
        _isLoading = false;
        notifyListeners();
        if (!_rcConfigured) {
          _configureRevenueCat(_defaultRcApiKey);
        }
      },
    );

    _whitelistSubscription?.cancel();
    _whitelistSubscription = _dbService.watchWhitelistedEmails().listen(
      (emails) {
        _whitelistedEmails = emails.map((e) => e.toLowerCase()).toList();
        _updatePremiumStatus();
      },
      onError: (error) {
        debugPrint("Error watching whitelisted emails: $error");
        _lastError = "Firestore whitelist error: $error";
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> _configureRevenueCat(String apiKey) async {
    if (_isConfiguring) return;
    _isConfiguring = true;
    _lastError = null;

    if (apiKey == "appl_placeholder_key" || apiKey == "YOUR_REVENUECAT_IOS_API_KEY_HERE" || apiKey.isEmpty) {
      debugPrint("RevenueCat: Using placeholder/default API key. Skipping configuration.");
      _rcConfigured = false;
      _isLoading = false;
      _isConfiguring = false;
      _lastError = "API key is placeholder/default: '$apiKey'";
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();
    try {
      final alreadyConfigured = await Purchases.isConfigured;
      if (!alreadyConfigured) {
        await Purchases.setLogLevel(LogLevel.debug);
        await Purchases.configure(PurchasesConfiguration(apiKey));
      }
      _rcConfigured = true;
      _configuredApiKey = apiKey;
      debugPrint("RevenueCat configured successfully.");

      // Setup customer info update listener
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _customerInfo = customerInfo;
        _updatePremiumStatus();
      });

      // Fetch initial customer info with a timeout
      try {
        _customerInfo = await Purchases.getCustomerInfo().timeout(const Duration(seconds: 10));
        _updatePremiumStatus();
      } catch (e) {
        debugPrint("Error fetching customer info during configuration: $e");
        _lastError = "CustomerInfo error: $e";
      }
      
      try {
        await _syncUserWithRevenueCat();
      } catch (e) {
        debugPrint("Error syncing user during configuration: $e");
        _lastError = "SyncUser error: $e";
      }
    } catch (e) {
      debugPrint("Error configuring RevenueCat: $e");
      _rcConfigured = false;
      _lastError = "Configure error: $e";
    } finally {
      _isConfiguring = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _syncUserWithRevenueCat() async {
    if (!_rcConfigured) return;
    try {
      final uid = _dbService.userId;
      if (uid != null) {
        debugPrint("RevenueCat: Logging in user $uid");
        final logInResult = await Purchases.logIn(uid).timeout(const Duration(seconds: 10));
        _customerInfo = logInResult.customerInfo;
      } else {
        debugPrint("RevenueCat: Logging out to anonymous session");
        _customerInfo = await Purchases.logOut().timeout(const Duration(seconds: 10));
      }
      _updatePremiumStatus();
      await _loadOfferings();
    } catch (e) {
      debugPrint("Error syncing user with RevenueCat: $e");
      _lastError = "SyncUser error: $e";
    }
  }

  Future<void> _loadOfferings() async {
    if (!_rcConfigured || _isLoadingOfferings) {
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoadingOfferings = true;
    _isLoading = true;
    notifyListeners();
    try {
      final offerings = await Purchases.getOfferings().timeout(const Duration(seconds: 10));
      _offerings = offerings;
      debugPrint("RevenueCat: Offerings loaded. Active Packages count: ${activePackages.length}");
    } catch (e) {
      debugPrint("Error loading offerings: $e");
      _lastError = "LoadOfferings error: $e";
    } finally {
      _isLoadingOfferings = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updatePremiumStatus() {
    final entitlements = _customerInfo?.entitlements.all;
    final hasActiveEntitlement = 
        (entitlements?['premium_access']?.isActive ?? false) ||
        (entitlements?['My Salon - Salon Management Pro']?.isActive ?? false);
    final userEmail = _auth.currentUser?.email?.toLowerCase();
    final isWhitelisted = userEmail != null && _whitelistedEmails.contains(userEmail);
    final globalEnabled = _systemConfig.subscriptionEnabled;

    debugPrint("[NMS-Billing] Status Update:");
    debugPrint("  - Firebase Auth UID: ${_auth.currentUser?.uid}");
    debugPrint("  - RevenueCat Original App User ID: ${_customerInfo?.originalAppUserId}");
    debugPrint("  - All Entitlements: ${entitlements?.keys.toList()}");
    debugPrint("  - Entitlement active ('premium_access' or 'My Salon - Salon Management Pro'): $hasActiveEntitlement");
    debugPrint("  - Whitelisted: $isWhitelisted (email: $userEmail)");
    debugPrint("  - Global Enabled: $globalEnabled");

    _isPremium = !globalEnabled || hasActiveEntitlement || isWhitelisted;
    debugPrint("  - Result isPremium: $_isPremium");
    notifyListeners();
  }

  // --- Purchase Actions ---

  Future<bool> purchasePackage(Package package) async {
    if (!_rcConfigured) return false;
    _isProcessingPurchase = true;
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint("[NMS-Billing] Purchasing package: ${package.identifier} (Product: ${package.storeProduct.identifier})");
      final purchaseResult = await Purchases.purchasePackage(package);
      debugPrint("[NMS-Billing] Purchase successful. originalAppUserId: ${purchaseResult.customerInfo.originalAppUserId}");
      _customerInfo = purchaseResult.customerInfo;
      _updatePremiumStatus();
      return _isPremium;
    } catch (e) {
      debugPrint("[NMS-Billing] Purchase failed: $e");
      return false;
    } finally {
      _isProcessingPurchase = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> restorePurchases() async {
    if (!_rcConfigured) return false;
    _isProcessingPurchase = true;
    _isLoading = true;
    notifyListeners();
    try {
      debugPrint("[NMS-Billing] Restoring purchases...");
      final customerInfo = await Purchases.restorePurchases();
      debugPrint("[NMS-Billing] Restore successful. originalAppUserId: ${customerInfo.originalAppUserId}");
      _customerInfo = customerInfo;
      _updatePremiumStatus();
      return _isPremium;
    } catch (e) {
      debugPrint("[NMS-Billing] Restore purchases failed: $e");
      return false;
    } finally {
      _isProcessingPurchase = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper method to set RevenueCat API Key (useful if fetched from external secure settings)
  void setApiKey(String key) {
    if (_rcApiKey != key) {
      _rcApiKey = key;
      if (_rcConfigured) {
        // Must restart or reconfigure if allowed, but since RevenueCat only configures once,
        // we log warning if already configured.
        debugPrint("Warning: API Key changed after configuration. Restart required to apply.");
      }
    }
  }

  @override
  void dispose() {
    _configSubscription?.cancel();
    _whitelistSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
