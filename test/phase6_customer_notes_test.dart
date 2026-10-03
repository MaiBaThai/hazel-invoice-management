import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/src/pigeon/mocks.dart';
import 'package:nms/core/providers/customer_provider.dart';
import 'package:nms/core/providers/subscription_provider.dart';
import 'package:nms/core/providers/settings_provider.dart';
import 'package:nms/core/providers/invoice_provider.dart';
import 'package:nms/data/models/customer_model.dart';
import 'package:nms/data/models/customer_note_model.dart';
import 'package:nms/data/models/invoice_model.dart';
import 'package:nms/data/services/database_service.dart';
import 'package:nms/features/customers/customer_detail_page.dart';

class MockCustomerDbService extends DatabaseService {
  final Map<String, List<CustomerNote>> mockNotes = {};
  final List<Customer> mockCustomers = [];
  final List<Invoice> mockInvoices = [];

  MockCustomerDbService()
      : super(
          userId: 'test_user',
          firestore: FakeFirebaseFirestore(),
        );

  @override
  Future<Customer?> getCustomer(String customerId) async {
    try {
      return mockCustomers.firstWhere((c) => c.id == customerId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Invoice>> getCustomerInvoices(String customerId) async {
    return mockInvoices.where((i) => i.customerId == customerId).toList();
  }

  @override
  Future<List<CustomerNote>> getCustomerNotes(String customerId) async {
    return List.from(mockNotes[customerId] ?? []);
  }

  @override
  Future<String> addCustomerNote(String customerId, String content) async {
    final list = mockNotes.putIfAbsent(customerId, () => []);
    final id = 'note_${list.length + 1}';
    final note = CustomerNote(
      id: id,
      content: content,
      createdAt: DateTime.now(),
    );
    list.insert(0, note);
    return id;
  }

  @override
  Future<void> updateCustomerNote(String customerId, String noteId, String content) async {
    final list = mockNotes[customerId];
    if (list != null) {
      final index = list.indexWhere((n) => n.id == noteId);
      if (index != -1) {
        list[index] = list[index].copyWith(
          content: content,
          updatedAt: DateTime.now(),
        );
      }
    }
  }

  @override
  Future<void> deleteCustomerNote(String customerId, String noteId) async {
    mockNotes[customerId]?.removeWhere((n) => n.id == noteId);
  }
}

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  group('Phase 6 Customer Detail Notes & Staff Badge Tests', () {
    late MockCustomerDbService mockDb;
    late CustomerProvider customerProvider;
    late SubscriptionProvider subProvider;
    late SettingsProvider settingsProvider;
    late InvoiceProvider invoiceProvider;

    final testCustomer = Customer(
      id: 'cust_1',
      name: 'Ngọc Lan',
      phone: '0901234567',
      totalSpent: 300.0,
    );

    final testInvoice = Invoice(
      id: 'inv_1',
      customerId: 'cust_1',
      customerName: 'Ngọc Lan',
      services: [ServiceItem(serviceName: 'Nail Ombre', price: 150.0)],
      photoUrls: const [],
      subtotal: 150.0,
      discountPercent: 0.0,
      finalTotal: 150.0,
      staffNames: ['Bảo', 'Ngọc'],
      commissionPercent: 10.0,
      tip: 20.0,
      notes: 'Thích móng nhọn, màu hồng nude',
      createdAt: DateTime(2026, 3, 15, 10, 30),
      sessionStart: DateTime(2026, 3, 15, 10, 0),
      sessionEnd: DateTime(2026, 3, 15, 11, 30),
    );

    setUp(() {
      mockDb = MockCustomerDbService();
      mockDb.mockCustomers.add(testCustomer);
      mockDb.mockInvoices.add(testInvoice);

      customerProvider = CustomerProvider(mockDb);
      subProvider = SubscriptionProvider(mockDb);
      settingsProvider = SettingsProvider(mockDb);
      invoiceProvider = InvoiceProvider(mockDb);
      invoiceProvider.updateCustomerProvider(customerProvider);
      invoiceProvider.updateSubscriptionProvider(subProvider);
    });

    Widget createTestApp(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<CustomerProvider>.value(value: customerProvider),
          ChangeNotifierProvider<SubscriptionProvider>.value(value: subProvider),
          ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
          ChangeNotifierProvider<InvoiceProvider>.value(value: invoiceProvider),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('CustomerDetailPage renders 3 tabs and displays Staff badge on Invoices tab', (tester) async {
      await tester.pumpWidget(createTestApp(const CustomerDetailPage(customerId: 'cust_1')));
      await tester.pumpAndSettle();

      // Verify 3 tabs are present
      expect(find.text('Invoices'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);

      // Verify Invoice card has Staff badge in trailing
      expect(find.text('Bảo, Ngọc'), findsOneWidget);

      // Tap on invoice to expand details
      await tester.tap(find.text('Bảo, Ngọc'));
      await tester.pumpAndSettle();

      // Expanded details show Staff, Commission, Tip, Notes
      expect(find.text('Staff: '), findsOneWidget);
      expect(find.text('Commission: '), findsOneWidget);
      expect(find.text('Tip: '), findsOneWidget);
      expect(find.text('Notes: '), findsOneWidget);
      expect(find.text('Thích móng nhọn, màu hồng nude'), findsOneWidget);
    });

    testWidgets('Notes tab displays invoice notes and allows adding/editing/deleting customer notes', (tester) async {
      await tester.pumpWidget(createTestApp(const CustomerDetailPage(customerId: 'cust_1')));
      await tester.pumpAndSettle();

      // Switch to Notes tab (index 2)
      await tester.tap(find.text('Notes'));
      await tester.pumpAndSettle();

      // Floating Action Button should be visible
      expect(find.text('Add Note'), findsWidgets);

      // Notes tab should show the linked invoice note with badge [Invoice - 15/03/2026]
      expect(find.text('[Invoice - 15/03/2026]'), findsOneWidget);
      expect(find.text('Thích móng nhọn, màu hồng nude'), findsOneWidget);

      // Add a new general customer note via FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add Customer Note'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'Dị ứng axeton đậm đặc');
      await tester.tap(find.text('ADD NOTE'));
      await tester.pumpAndSettle();

      // Verify the new note appears in the Customer Notes section
      expect(find.text('Customer Notes'), findsOneWidget);
      expect(find.text('Dị ứng axeton đậm đặc'), findsOneWidget);

      // Edit the customer note
      await tester.tap(find.byTooltip('Edit Note'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Customer Note'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, 'Dị ứng axeton đậm đặc, chỉ dùng loại nhẹ');
      await tester.tap(find.text('UPDATE'));
      await tester.pumpAndSettle();

      expect(find.text('Dị ứng axeton đậm đặc, chỉ dùng loại nhẹ'), findsOneWidget);

      // Delete the customer note
      await tester.tap(find.byTooltip('Delete Note'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Note?'), findsOneWidget);
      await tester.tap(find.text('DELETE'));
      await tester.pumpAndSettle();

      // Customer note should be gone, invoice note remains
      expect(find.text('Dị ứng axeton đậm đặc, chỉ dùng loại nhẹ'), findsNothing);
      expect(find.text('[Invoice - 15/03/2026]'), findsOneWidget);
    });
  });
}
