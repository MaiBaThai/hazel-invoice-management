import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/src/pigeon/mocks.dart';
import 'package:nms/core/providers/invoice_provider.dart';
import 'package:nms/core/providers/staff_provider.dart';
import 'package:nms/core/providers/settings_provider.dart';
import 'package:nms/core/providers/subscription_provider.dart';
import 'package:nms/core/providers/customer_provider.dart';
import 'package:nms/data/models/staff_model.dart';
import 'package:nms/data/models/customer_model.dart';
import 'package:nms/data/services/database_service.dart';
import 'package:nms/features/invoice/invoice_page.dart';
import 'package:nms/features/invoice/widgets/invoice_summary_dialog.dart';

class MockInvoiceDbService extends DatabaseService {
  final List<Staff> mockStaffList = [];
  final List<Customer> mockCustomers = [];

  MockInvoiceDbService()
      : super(
          userId: 'test_user',
          firestore: FakeFirebaseFirestore(),
        );

  @override
  Future<List<Staff>> getStaffList() async {
    return List.from(mockStaffList);
  }

  @override
  Future<List<Customer>> getCustomers() async {
    return List.from(mockCustomers);
  }
}

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  group('Phase 5 Invoice UI Tests', () {
    late MockInvoiceDbService mockDb;
    late StaffProvider staffProvider;
    late InvoiceProvider invoiceProvider;
    late SettingsProvider settingsProvider;
    late SubscriptionProvider subProvider;
    late CustomerProvider customerProvider;

    setUp(() {
      mockDb = MockInvoiceDbService();
      staffProvider = StaffProvider(mockDb);
      settingsProvider = SettingsProvider(mockDb);
      subProvider = SubscriptionProvider(mockDb);
      customerProvider = CustomerProvider(mockDb);
      invoiceProvider = InvoiceProvider(mockDb);
      invoiceProvider.updateCustomerProvider(customerProvider);
      invoiceProvider.updateSubscriptionProvider(subProvider);

      mockDb.mockStaffList.addAll([
        Staff(
          id: 's1',
          name: 'Bảo',
          phone: '0901111111',
          defaultCommissionPercent: 15.0,
          createdAt: DateTime.now(),
          isActive: true,
        ),
        Staff(
          id: 's2',
          name: 'Ngọc',
          phone: '0902222222',
          defaultCommissionPercent: 10.0,
          createdAt: DateTime.now(),
          isActive: true,
        ),
      ]);
      staffProvider.loadStaff();
    });

    Widget createTestApp(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<StaffProvider>.value(value: staffProvider),
          ChangeNotifierProvider<InvoiceProvider>.value(value: invoiceProvider),
          ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
          ChangeNotifierProvider<SubscriptionProvider>.value(value: subProvider),
          ChangeNotifierProvider<CustomerProvider>.value(value: customerProvider),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('InvoicePage displays staff chips and toggling updates provider & commission', (tester) async {
      await tester.pumpWidget(createTestApp(const InvoicePage()));
      await tester.pumpAndSettle();

      // Verify Staff section is visible
      expect(find.text('Staff'), findsOneWidget);
      expect(find.text('Bảo'), findsOneWidget);
      expect(find.text('Ngọc'), findsOneWidget);

      // Tap on 'Bảo' chip
      await tester.tap(find.text('Bảo'));
      await tester.pumpAndSettle();

      // Verify Bảo is selected
      expect(invoiceProvider.selectedStaffNames, contains('Bảo'));
      // Default commission of 15% should be populated
      expect(invoiceProvider.commissionPercent, equals(15.0));
      expect(find.text('1 selected'), findsOneWidget);

      // Tap on 'Ngọc' chip
      await tester.tap(find.text('Ngọc'));
      await tester.pumpAndSettle();

      expect(invoiceProvider.selectedStaffNames, containsAll(['Bảo', 'Ngọc']));
      expect(find.text('2 selected'), findsOneWidget);
    });

    testWidgets('InvoicePage handles Commission, Tip, and Notes inputs correctly', (tester) async {
      invoiceProvider.addService();
      invoiceProvider.updateService(0, 'Nail Art', 100.0);

      await tester.pumpWidget(createTestApp(const InvoicePage()));
      await tester.pumpAndSettle();

      // Find Commission and Tip inputs
      expect(find.text('Commission (%)'), findsOneWidget);
      expect(find.text('Tip'), findsOneWidget);
      expect(find.text('Invoice Notes'), findsOneWidget);

      final textFields = find.byType(TextField);
      // Service name = 0, price = 1, discount = 2, commission = 3, tip = 4, notes = 5
      await tester.enterText(textFields.at(3), '20'); // commission
      await tester.pumpAndSettle();
      expect(invoiceProvider.commissionPercent, equals(20.0));

      await tester.enterText(textFields.at(4), '50'); // tip
      await tester.pumpAndSettle();
      expect(invoiceProvider.tip, equals(50.0));
      // Total (Customer bill) does NOT add tip
      expect(invoiceProvider.finalTotal, equals(100.0));
      // Staff tip notice should appear
      expect(find.text('+ Staff Tip'), findsOneWidget);

      // Scroll to reveal Notes TextField if necessary
      await tester.ensureVisible(textFields.at(5));
      await tester.enterText(textFields.at(5), 'Customer likes subtle glitter');
      await tester.pumpAndSettle();
      expect(invoiceProvider.notes, equals('Customer likes subtle glitter'));
    });

    testWidgets('InvoiceSummaryDialog renders staff on receipt, but hides internal summary, commission, tip, and notes', (tester) async {
      invoiceProvider.selectCustomer(Customer(
        id: 'c1',
        name: 'Anna Smith',
        phone: '0901234567',
      ));
      invoiceProvider.addService();
      invoiceProvider.updateService(0, 'Manicure', 80.0);
      invoiceProvider.toggleStaffName('Bảo');
      invoiceProvider.setCommissionPercent(15.0);
      invoiceProvider.setTip(20.0);
      invoiceProvider.setNotes('Prefers almond shape');

      await tester.pumpWidget(createTestApp(const InvoiceSummaryDialog()));
      await tester.pumpAndSettle();

      // Receipt contains STAFF: Bảo
      expect(find.text('STAFF: '), findsOneWidget);
      expect(find.text('Bảo'), findsWidgets);

      // Internal summary is completely removed (not shown to customer)
      expect(find.text('INTERNAL SUMMARY (NOT ON RECEIPT)'), findsNothing);
      expect(find.text('Commission (15.0%):'), findsNothing);
      expect(find.text('Staff Tip:'), findsNothing);
      expect(find.text('Prefers almond shape'), findsNothing);
    });
  });
}
