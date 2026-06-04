import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:nms/data/services/database_service.dart';
import 'package:nms/data/models/customer_model.dart';
import 'package:nms/data/models/app_settings_model.dart';

void main() {
  group('DatabaseService - Lazy Firestore Creation Tests', () {
    late FakeFirebaseFirestore fakeDb;

    setUp(() {
      fakeDb = FakeFirebaseFirestore();
    });

    test('Registered user: syncUser and getSettings should create documents immediately', () async {
      final dbService = DatabaseService(
        userId: 'reg_user_123',
        isAnonymous: false,
        firestore: fakeDb,
      );

      // 1. Sync User on startup
      await dbService.syncUser();

      // Verify users/reg_user_123 doc is created
      final userDoc = await fakeDb.collection('users').doc('reg_user_123').get();
      expect(userDoc.exists, isTrue);
      expect(userDoc.data()?['uid'], equals('reg_user_123'));

      // 2. Load settings
      final settings = await dbService.getSettings();
      expect(settings, isNotNull);

      // Verify that settings document is NOT automatically written in our updated logic.
      final settingsDoc = await fakeDb
          .collection('users')
          .doc('reg_user_123')
          .collection('configs')
          .doc('app_settings')
          .get();
      expect(settingsDoc.exists, isFalse);
    });

    test('Anonymous user: syncUser and getSettings should NOT create documents on startup', () async {
      final dbService = DatabaseService(
        userId: 'anon_user_123',
        isAnonymous: true,
        firestore: fakeDb,
      );

      // 1. Sync User (should be skipped for anonymous)
      await dbService.syncUser();

      // Verify users/anon_user_123 doc is NOT created
      final userDoc = await fakeDb.collection('users').doc('anon_user_123').get();
      expect(userDoc.exists, isFalse);

      // 2. Get Settings (should return defaults in-memory, no writes)
      final settings = await dbService.getSettings();
      expect(settings.businessConfig.businessName, equals('My Salon')); // default name

      // Verify settings doc is NOT created
      final settingsDoc = await fakeDb
          .collection('users')
          .doc('anon_user_123')
          .collection('configs')
          .doc('app_settings')
          .get();
      expect(settingsDoc.exists, isFalse);
    });

    test('Anonymous user: first write action should trigger on-demand parent creation', () async {
      final dbService = DatabaseService(
        userId: 'anon_user_123',
        isAnonymous: true,
        firestore: fakeDb,
      );

      // Initially, no user profile document exists
      var userDoc = await fakeDb.collection('users').doc('anon_user_123').get();
      expect(userDoc.exists, isFalse);

      // Perform a write action (add a customer)
      final customer = Customer(
        id: '',
        name: 'Jane Doe',
        phone: '1234567890',
        totalSpent: 0.0,
      );
      await dbService.addCustomer(customer);

      // Verify that the parent users/anon_user_123 doc is created on-demand
      userDoc = await fakeDb.collection('users').doc('anon_user_123').get();
      expect(userDoc.exists, isTrue);
      expect(userDoc.data()?['uid'], equals('anon_user_123'));
      expect(userDoc.data()?['note'], equals('Auto-created on first write'));

      // Verify that the customer was added to the subcollection
      final customers = await fakeDb
          .collection('users')
          .doc('anon_user_123')
          .collection('customers')
          .get();
      expect(customers.docs.length, equals(1));
      expect(customers.docs.first.data()['name'], equals('Jane Doe'));
    });

    test('Anonymous user: modifying settings should trigger on-demand parent and settings document creation', () async {
      final dbService = DatabaseService(
        userId: 'anon_user_123',
        isAnonymous: true,
        firestore: fakeDb,
      );

      // Create new settings to update
      final newSettings = AppSettings(
        businessConfig: BusinessConfig(businessName: 'Custom Salon Name', currencySymbol: 'k'),
        bankConfig: BankConfig(bankName: '', accountNumber: '', accountName: ''),
        predefinedServices: [],
      );

      // Write settings
      await dbService.updateSettings(newSettings);

      // Verify parent document is created
      final userDoc = await fakeDb.collection('users').doc('anon_user_123').get();
      expect(userDoc.exists, isTrue);

      // Verify settings document is written
      final settingsDoc = await fakeDb
          .collection('users')
          .doc('anon_user_123')
          .collection('configs')
          .doc('app_settings')
          .get();
      expect(settingsDoc.exists, isTrue);
      expect(settingsDoc.data()?['business_config']?['business_name'], equals('Custom Salon Name'));
    });
  });
}
