import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nms/data/services/database_service.dart';
import 'package:nms/data/models/invoice_model.dart';
import 'package:nms/data/models/customer_model.dart';
import 'package:nms/data/models/system_config_model.dart';
import 'package:nms/core/providers/invoice_provider.dart';
import 'package:nms/core/providers/subscription_provider.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

// Simple mock/fake for SubscriptionProvider to isolate InvoiceProvider tests
class FakeSubscriptionProvider extends SubscriptionProvider {
  bool _mockPremium = false;
  int _mockLimit = 50;

  FakeSubscriptionProvider(super.dbService, {super.auth});

  @override
  bool get isPremium => _mockPremium;

  @override
  int get freeInvoiceLimit => _mockLimit;

  void setMockPremium(bool val) {
    _mockPremium = val;
  }

  void setMockLimit(int val) {
    _mockLimit = val;
  }
}

void main() {
  group('Subscription & Invoices limit Tests', () {
    late FakeFirebaseFirestore fakeDb;
    late DatabaseService dbService;
    late MockFirebaseAuth mockAuth;

    setUp(() {
      fakeDb = FakeFirebaseFirestore();
      dbService = DatabaseService(
        userId: 'user_123',
        isAnonymous: false,
        firestore: fakeDb,
      );
      mockAuth = MockFirebaseAuth();
      when(() => mockAuth.userChanges()).thenAnswer((_) => const Stream<User?>.empty());
      when(() => mockAuth.currentUser).thenReturn(null);
    });

    test('getInvoiceCountForMonth: should accurately count invoices created in the given calendar month', () async {
      // Add invoices for July 2026
      final invoiceJuly1 = {
        'customer_id': 'cust_a',
        'customer_name': 'Alice',
        'created_at': Timestamp.fromDate(DateTime(2026, 7, 5, 10, 0)),
        'services': [],
        'subtotal': 50.0,
        'discount_percent': 0.0,
        'final_total': 50.0,
        'photoUrls': [],
      };
      final invoiceJuly2 = {
        ...invoiceJuly1,
        'created_at': Timestamp.fromDate(DateTime(2026, 7, 31, 23, 59)),
      };
      
      // Add invoice for August 2026
      final invoiceAug = {
        ...invoiceJuly1,
        'created_at': Timestamp.fromDate(DateTime(2026, 8, 1, 0, 0)),
      };

      // Add to Firestore
      final invoicesCollection = fakeDb.collection('users').doc('user_123').collection('invoices');
      await invoicesCollection.add(invoiceJuly1);
      await invoicesCollection.add(invoiceJuly2);
      await invoicesCollection.add(invoiceAug);

      // Verify counts
      final countJuly = await dbService.getInvoiceCountForMonth(2026, 7);
      final countAug = await dbService.getInvoiceCountForMonth(2026, 8);
      final countJune = await dbService.getInvoiceCountForMonth(2026, 6);

      expect(countJuly, equals(2));
      expect(countAug, equals(1));
      expect(countJune, equals(0));
    });

    test('checkCanSaveInvoice: should enforce free tier limit', () async {
      final fakeSub = FakeSubscriptionProvider(dbService, auth: mockAuth);
      final invoiceProvider = InvoiceProvider(dbService);
      invoiceProvider.updateSubscriptionProvider(fakeSub);

      // 1. Unsubscribed user under the limit (count: 0, limit: 2)
      fakeSub.setMockPremium(false);
      fakeSub.setMockLimit(2);
      expect(await invoiceProvider.checkCanSaveInvoice(), isTrue);

      // Add two invoices to reach limit
      final invoicesCollection = fakeDb.collection('users').doc('user_123').collection('invoices');
      final now = DateTime.now();
      final invoiceDoc = {
        'customer_id': 'cust_a',
        'customer_name': 'Alice',
        'created_at': Timestamp.fromDate(now),
        'services': [],
        'subtotal': 50.0,
        'discount_percent': 0.0,
        'final_total': 50.0,
        'photoUrls': [],
      };
      await invoicesCollection.add(invoiceDoc);
      await invoicesCollection.add(invoiceDoc);

      // 2. Unsubscribed user at/over the limit (count: 2, limit: 2)
      expect(await invoiceProvider.checkCanSaveInvoice(), isFalse);

      // 3. Subscribed user over the limit (should bypass limit)
      fakeSub.setMockPremium(true);
      expect(await invoiceProvider.checkCanSaveInvoice(), isTrue);

      // 4. Unsubscribed user over the limit but editing existing invoice (should bypass limit)
      fakeSub.setMockPremium(false);
      invoiceProvider.loadInvoiceForEditing(
        Invoice(
          id: 'existing_inv_id',
          customerId: 'cust_a',
          customerName: 'Alice',
          createdAt: now,
          services: [],
          subtotal: 50.0,
          discountPercent: 0.0,
          finalTotal: 50.0,
          photoUrls: [],
        ),
        Customer(id: 'cust_a', name: 'Alice', phone: '', totalSpent: 50.0),
      );
      expect(await invoiceProvider.checkCanSaveInvoice(), isTrue);
    });
  });
}
