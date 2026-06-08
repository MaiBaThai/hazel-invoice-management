import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:nms/data/models/customer_model.dart';
import 'package:nms/data/services/database_service.dart';
import 'package:nms/core/providers/customer_provider.dart';

class MockDatabaseServiceWithError extends DatabaseService {
  MockDatabaseServiceWithError(FakeFirebaseFirestore fakeDb) 
      : super(userId: 'user_123', firestore: fakeDb);

  @override
  Future<List<Customer>> getCustomers() async {
    throw Exception('Simulated database fetch failure');
  }
}

void main() {
  group('CustomerProvider Error Handling Tests', () {
    late FakeFirebaseFirestore fakeDb;

    setUp(() {
      fakeDb = FakeFirebaseFirestore();
    });

    test('should set hasError to true and keep hasLoadedOnce as false on load failure', () async {
      final badDbService = MockDatabaseServiceWithError(fakeDb);
      final provider = CustomerProvider(badDbService);

      expect(provider.hasLoadedOnce, isFalse);
      expect(provider.hasError, isFalse);

      await provider.loadCustomers();

      expect(provider.hasLoadedOnce, isFalse);
      expect(provider.hasError, isTrue);
    });

    test('should reset hasError on database service update', () async {
      final badDbService = MockDatabaseServiceWithError(fakeDb);
      final provider = CustomerProvider(badDbService);

      await provider.loadCustomers();
      expect(provider.hasError, isTrue);

      // Simulate sign in / sign out transition
      final cleanDbService = DatabaseService(userId: 'new_user_456', firestore: fakeDb);
      provider.updateDbService(cleanDbService);

      expect(provider.hasError, isFalse);
      expect(provider.hasLoadedOnce, isFalse);
    });
  });
}
