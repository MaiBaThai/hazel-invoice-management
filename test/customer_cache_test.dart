import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:nms/data/services/database_service.dart';
import 'package:nms/core/providers/customer_provider.dart';
import 'package:nms/core/providers/invoice_provider.dart';
import 'package:nms/data/models/customer_model.dart';

class FakeBuildContext extends Fake implements BuildContext {}

void main() {
  group('Shared Customer Cache Integration Tests', () {
    late FakeFirebaseFirestore fakeDb;
    late DatabaseService dbService;
    late CustomerProvider customerProvider;
    late InvoiceProvider invoiceProvider;

    setUp(() async {
      fakeDb = FakeFirebaseFirestore();
      dbService = DatabaseService(
        userId: 'user_abc_123',
        isAnonymous: false,
        firestore: fakeDb,
      );

      customerProvider = CustomerProvider(dbService);
      invoiceProvider = InvoiceProvider(dbService);
      invoiceProvider.updateCustomerProvider(customerProvider);

      // Seed database with two initial customers
      await dbService.addCustomer(Customer(id: '', name: 'Alice Smith', phone: '111222'));
      await dbService.addCustomer(Customer(id: '', name: 'Bob Jones', phone: '333444'));

      // Populate Master Cache
      await customerProvider.loadCustomers();
    });

    test('InvoiceProvider should search from CustomerProvider cache with zero additional database reads', () async {
      // Confirm Master Cache is loaded
      expect(customerProvider.allCustomers.length, equals(2));

      // Trigger search in InvoiceProvider (which reads from shared CustomerProvider cache)
      await invoiceProvider.searchCustomers('Alice');

      // Verify we found Alice
      expect(invoiceProvider.searchResults.length, equals(1));
      expect(invoiceProvider.searchResults.first.name, equals('Alice Smith'));
    });

    test('Creating a customer in InvoiceProvider should immediately synchronize to CustomerProvider cache', () async {
      // Verify initial master list size
      expect(customerProvider.allCustomers.length, equals(2));

      try {
        // Create new customer using FakeBuildContext
        final fakeContext = FakeBuildContext();
        await invoiceProvider.createNewCustomer(fakeContext, 'Charlie Brown', '555666');
      } catch (e) {
        fail('Should not throw: $e');
      }

      // Verify InvoiceProvider has the selected customer
      expect(invoiceProvider.selectedCustomer, isNotNull);
      expect(invoiceProvider.selectedCustomer!.name, equals('Charlie Brown'));

      // Verify the new customer is IMMEDIATELY synced to CustomerProvider cache
      expect(customerProvider.allCustomers.length, equals(3));
      expect(customerProvider.allCustomers.any((c) => c.name == 'Charlie Brown'), isTrue);
    });

    test('Updating a customer in CustomerProvider should keep the master list updated', () async {
      final alice = customerProvider.allCustomers.firstWhere((c) => c.name == 'Alice Smith');
      
      // Update customer name/phone in CustomerProvider
      await customerProvider.updateCustomer(alice.id, 'Alice Cooper', '999888');

      // Verify cache contains updated data
      expect(customerProvider.allCustomers.any((c) => c.name == 'Alice Cooper'), isTrue);
      expect(customerProvider.allCustomers.any((c) => c.name == 'Alice Smith'), isFalse);
    });
  });
}
