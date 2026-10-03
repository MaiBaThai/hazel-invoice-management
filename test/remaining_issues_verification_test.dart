import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/src/pigeon/mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nms/core/providers/customer_provider.dart';
import 'package:nms/core/providers/invoice_provider.dart';
import 'package:nms/core/providers/settings_provider.dart';
import 'package:nms/core/providers/staff_provider.dart';
import 'package:nms/core/providers/subscription_provider.dart';
import 'package:nms/data/models/customer_model.dart';
import 'package:nms/data/models/customer_note_model.dart';
import 'package:nms/data/models/invoice_model.dart';
import 'package:nms/data/models/staff_model.dart';
import 'package:nms/data/services/database_service.dart';
import 'package:nms/features/customers/customer_detail_page.dart';
import 'package:nms/features/invoice/invoice_page.dart';
import 'package:nms/features/invoice/widgets/invoice_summary_dialog.dart';
import 'package:provider/provider.dart';

class MockTestDbService extends DatabaseService {
  final List<Staff> mockStaffList = [];
  final List<Customer> mockCustomers = [];
  final List<Invoice> mockInvoices = [];

  MockTestDbService()
      : super(
          userId: 'test_user_remaining',
          firestore: FakeFirebaseFirestore(),
        );

  @override
  Future<List<Staff>> getStaffList() async => List.from(mockStaffList);

  @override
  Future<List<Customer>> getCustomers() async => List.from(mockCustomers);

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
  Future<List<CustomerNote>> getCustomerNotes(String customerId) async => [];
}

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  group('Remaining Issues Verification Tests', () {
    late MockTestDbService mockDb;
    late StaffProvider staffProvider;
    late CustomerProvider customerProvider;
    late InvoiceProvider invoiceProvider;
    late SettingsProvider settingsProvider;
    late SubscriptionProvider subProvider;

    setUp(() {
      mockDb = MockTestDbService();
      staffProvider = StaffProvider(mockDb);
      customerProvider = CustomerProvider(mockDb);
      invoiceProvider = InvoiceProvider(mockDb);
      settingsProvider = SettingsProvider(mockDb);
      subProvider = SubscriptionProvider(mockDb);

      invoiceProvider.updateCustomerProvider(customerProvider);
      invoiceProvider.updateSubscriptionProvider(subProvider);
    });

    Widget createTestApp(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<StaffProvider>.value(value: staffProvider),
          ChangeNotifierProvider<CustomerProvider>.value(value: customerProvider),
          ChangeNotifierProvider<InvoiceProvider>.value(value: invoiceProvider),
          ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
          ChangeNotifierProvider<SubscriptionProvider>.value(value: subProvider),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('INV-02: Selecting staff auto-fills exact default commission (15%) and clearing staff resets commission', (tester) async {
      mockDb.mockStaffList.add(Staff(
        id: 's1',
        name: 'Trang',
        phone: '0912345678',
        defaultCommissionPercent: 15.0,
        createdAt: DateTime.now(),
      ));

      await tester.pumpWidget(createTestApp(const InvoicePage()));
      await tester.pumpAndSettle();

      // Tap staff chip Trang
      final trangChip = find.text('Trang');
      expect(trangChip, findsOneWidget);
      await tester.tap(trangChip);
      await tester.pumpAndSettle();

      // Commission percent in provider and controller should be 15
      expect(invoiceProvider.commissionPercent, equals(15.0));
      expect(find.text('15'), findsWidgets);

      // Deselect Trang chip
      await tester.tap(trangChip);
      await tester.pumpAndSettle();

      // Commission should reset to 0 and controller cleared
      expect(invoiceProvider.commissionPercent, equals(0.0));
      expect(invoiceProvider.selectedStaffNames, isEmpty);
    });

    testWidgets('INV-02: Select staff A (10%), select staff B (15%), unselect staff A -> commission updates to 15%', (tester) async {
      mockDb.mockStaffList.addAll([
        Staff(
          id: 's_a',
          name: 'Staff A',
          phone: '0901',
          defaultCommissionPercent: 10.0,
          createdAt: DateTime.now(),
        ),
        Staff(
          id: 's_b',
          name: 'Staff B',
          phone: '0902',
          defaultCommissionPercent: 15.0,
          createdAt: DateTime.now(),
        ),
      ]);

      await tester.pumpWidget(createTestApp(const InvoicePage()));
      await tester.pumpAndSettle();

      final staffAChip = find.text('Staff A');
      final staffBChip = find.text('Staff B');

      // 1. Select Staff A (10%)
      await tester.tap(staffAChip);
      await tester.pumpAndSettle();
      expect(invoiceProvider.commissionPercent, equals(10.0));
      expect(find.text('10'), findsWidgets);

      // 2. Select Staff B (15%)
      await tester.tap(staffBChip);
      await tester.pumpAndSettle();
      expect(invoiceProvider.selectedStaffNames, containsAll(['Staff A', 'Staff B']));

      // 3. Unselect Staff A -> Remaining staff is Staff B (15%)
      await tester.tap(staffAChip);
      await tester.pumpAndSettle();

      expect(invoiceProvider.selectedStaffNames, equals(['Staff B']));
      expect(invoiceProvider.commissionPercent, equals(15.0));
      expect(find.text('15'), findsWidgets);
    });

    testWidgets('INV-07: InvoiceSummaryDialog has NO internal summary, but editing invoice displays all loaded details and notice banner', (tester) async {
      final customer = Customer(id: 'c1', name: 'John Doe', phone: '090111222');
      final invoice = Invoice(
        id: 'inv_edit_99',
        customerId: 'c1',
        customerName: 'John Doe',
        staffNames: ['Trang'],
        tip: 25.0,
        commissionPercent: 15.0,
        notes: 'VIP customer likes mint tea',
        services: [ServiceItem(serviceName: 'Manicure Luxury', price: 120.0)],
        subtotal: 120.0,
        discountPercent: 10.0,
        finalTotal: 108.0,
        photoUrls: const [],
        createdAt: DateTime.now(),
      );

      mockDb.mockStaffList.add(Staff(
        id: 's1',
        name: 'Trang',
        phone: '0912345678',
        defaultCommissionPercent: 15.0,
        createdAt: DateTime.now(),
      ));

      // 1. Verify summary dialog has NO internal summary
      invoiceProvider.loadInvoiceForEditing(invoice, customer);
      await tester.pumpWidget(createTestApp(const InvoiceSummaryDialog()));
      await tester.pumpAndSettle();

      expect(find.text('INTERNAL SUMMARY (NOT ON RECEIPT)'), findsNothing);
      expect(find.text('Staff Tip:'), findsNothing);

      // 2. Open InvoicePage in editing mode
      await tester.pumpWidget(createTestApp(const InvoicePage()));
      await tester.pumpAndSettle();

      // Verify editing notice banner is displayed (without invoice ID)
      expect(find.text('Editing Invoice'), findsOneWidget);
      expect(find.text('REVIEW & UPDATE'), findsOneWidget);

      // Verify fields are loaded with invoice data
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Manicure Luxury'), findsOneWidget);
      expect(find.text('10'), findsWidgets); // discount
      expect(find.text('15'), findsWidgets); // commission
      expect(find.text('25'), findsWidgets); // tip
      expect(find.text('VIP customer likes mint tea'), findsOneWidget); // notes
    });

    testWidgets('CUS-02: Customer Invoices tab displays Date and Timestamp row aligned with Staff badge', (tester) async {
      final customer = Customer(id: 'c_test', name: 'Test User', phone: '123456');
      final invoice = Invoice(
        id: 'inv_time_1',
        customerId: 'c_test',
        customerName: 'Test User',
        services: [ServiceItem(serviceName: 'Pedicure', price: 50.0)],
        photoUrls: const [],
        subtotal: 50.0,
        discountPercent: 0.0,
        finalTotal: 50.0,
        staffNames: ['Trang'],
        sessionStart: DateTime(2026, 8, 20, 16, 0),
        sessionEnd: DateTime(2026, 8, 20, 16, 30),
        createdAt: DateTime(2026, 8, 20, 16, 0),
      );

      mockDb.mockCustomers.add(customer);
      mockDb.mockInvoices.add(invoice);

      await tester.pumpWidget(createTestApp(const CustomerDetailPage(customerId: 'c_test')));
      await tester.pumpAndSettle();

      // Check date
      expect(find.text('20/08/2026'), findsOneWidget);
      // Check timestamp range right below date
      expect(find.text('16:00 - 16:30'), findsOneWidget);
      // Check staff badge
      expect(find.text('Trang'), findsOneWidget);
    });

    testWidgets('CUS-04: Customer Notes tab has no quick add card at top, shows default text when empty, and Add Note button', (tester) async {
      final customer = Customer(id: 'c_empty', name: 'Empty Notes User', phone: '999');
      mockDb.mockCustomers.add(customer);

      await tester.pumpWidget(createTestApp(const CustomerDetailPage(customerId: 'c_empty')));
      await tester.pumpAndSettle();

      // Switch to Notes tab
      await tester.tap(find.text('Notes'));
      await tester.pumpAndSettle();

      // Top quick add card should be gone
      expect(find.text('Write a new note for this customer...'), findsNothing);

      // Empty state text should match user request
      expect(
        find.text('Enter notes for customer (e.g. skin sensitivity, preferences...)'),
        findsOneWidget,
      );

      // Exactly ONE Add Note button exists on screen (no duplicate button)
      expect(find.text('Add Note'), findsOneWidget);
    });

    testWidgets('CUS-04: Customer Notes tab with existing notes has exactly ONE Add Note button (FloatingActionButton)', (tester) async {
      final customer = Customer(id: 'c_notes', name: 'User With Notes', phone: '888');
      final invoice = Invoice(
        id: 'inv_note_1',
        customerId: 'c_notes',
        customerName: 'User With Notes',
        notes: 'notes thêm',
        staffNames: ['Bích Bảo'],
        services: [ServiceItem(serviceName: 'Manicure', price: 30.0)],
        photoUrls: const [],
        subtotal: 30.0,
        discountPercent: 0.0,
        finalTotal: 30.0,
        createdAt: DateTime(2026, 10, 3),
      );

      mockDb.mockCustomers.add(customer);
      mockDb.mockInvoices.add(invoice);

      await tester.pumpWidget(createTestApp(const CustomerDetailPage(customerId: 'c_notes')));
      await tester.pumpAndSettle();

      // Switch to Notes tab
      await tester.tap(find.text('Notes'));
      await tester.pumpAndSettle();

      // Verify Customer Notes section and prompt text are ALWAYS visible when customer notes are empty
      expect(find.text('Customer Notes'), findsOneWidget);
      expect(
        find.text('Enter notes for customer (e.g. skin sensitivity, preferences...)'),
        findsOneWidget,
      );

      // Verify Notes from Invoices section and the invoice note are rendered
      expect(find.text('Notes from Invoices'), findsOneWidget);
      expect(find.text('notes thêm'), findsOneWidget);
      expect(find.text('Staff: Bích Bảo'), findsOneWidget);

      // Verify there is strictly ONE Add Note button on the screen
      expect(find.text('Add Note'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}
