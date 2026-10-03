import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:nms/core/providers/staff_provider.dart';
import 'package:nms/core/providers/settings_provider.dart';
import 'package:nms/data/models/staff_model.dart';
import 'package:nms/data/models/invoice_model.dart';
import 'package:nms/data/services/database_service.dart';
import 'package:nms/features/staff/staffs_page.dart';
import 'package:nms/features/staff/staff_detail_page.dart';

class MockStaffDbService extends DatabaseService {
  final List<Staff> mockStaffList = [];
  final List<Invoice> mockInvoicesList = [];

  MockStaffDbService()
      : super(
          userId: 'test_user',
          firestore: FakeFirebaseFirestore(),
        );

  @override
  Future<List<Staff>> getStaffList() async {
    return List.from(mockStaffList);
  }

  @override
  Future<Staff?> getStaff(String staffId) async {
    try {
      return mockStaffList.firstWhere((s) => s.id == staffId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> addStaff(Staff staff) async {
    final id = 'staff_${mockStaffList.length + 1}';
    mockStaffList.add(staff.copyWith(id: id));
    return id;
  }

  @override
  Future<void> updateStaff(Staff staff) async {
    final idx = mockStaffList.indexWhere((s) => s.id == staff.id);
    if (idx != -1) {
      mockStaffList[idx] = staff;
    }
  }

  @override
  Future<void> deleteStaff(String staffId) async {
    mockStaffList.removeWhere((s) => s.id == staffId);
  }

  @override
  Future<List<Invoice>> getStaffInvoices(String staffName) async {
    return mockInvoicesList.where((inv) => inv.staffNames.contains(staffName)).toList();
  }
}

void main() {
  group('Phase 4 Staff UI Tests', () {
    late MockStaffDbService mockDb;
    late StaffProvider staffProvider;
    late SettingsProvider settingsProvider;

    setUp(() {
      mockDb = MockStaffDbService();
      staffProvider = StaffProvider(mockDb);
      settingsProvider = SettingsProvider(mockDb);
    });

    testWidgets('StaffsPage: renders, opens Add Staff dialog, and adds a staff member', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<StaffProvider>.value(value: staffProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
          ],
          child: const MaterialApp(
            home: StaffsPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify empty state
      expect(find.text('No staff members yet'), findsOneWidget);

      // Tap FAB "Add Staff"
      await tester.tap(find.text('Add Staff'));
      await tester.pumpAndSettle();

      expect(find.text('Add New Staff Member'), findsOneWidget);

      // Enter Name and Commission %
      await tester.enterText(find.widgetWithText(TextFormField, 'Staff Name *'), 'Bảo');
      await tester.enterText(find.widgetWithText(TextFormField, 'Default Commission (%)'), '15');
      await tester.pumpAndSettle();

      // Tap SAVE
      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();

      // Verify staff list now has Bảo
      expect(find.text('Bảo'), findsOneWidget);
      expect(find.text('15% Comm'), findsOneWidget);
    });

    testWidgets('StaffDetailPage: displays metrics, earnings, and served invoices', (tester) async {
      final staff = Staff(
        id: 'staff_1',
        name: 'Ngọc',
        phone: '0987654321',
        defaultCommissionPercent: 10.0,
        createdAt: DateTime.now(),
        isActive: true,
      );
      mockDb.mockStaffList.add(staff);

      mockDb.mockInvoicesList.add(Invoice(
        id: 'inv_101',
        customerId: 'c1',
        customerName: 'Lan Hương',
        services: [ServiceItem(serviceName: 'Full Set Nail', price: 100.0)],
        subtotal: 100.0,
        discountPercent: 0.0,
        finalTotal: 100.0,
        photoUrls: [],
        createdAt: DateTime.now(),
        staffNames: ['Ngọc'],
        commissionPercent: 10.0, // 10.0 comm
        tip: 25.0, // 25.0 tip
        notes: 'Khách tip thêm',
      ));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<StaffProvider>.value(value: staffProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
          ],
          child: const MaterialApp(
            home: StaffDetailPage(staffId: 'staff_1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Staff info
      expect(find.text('Ngọc'), findsWidgets);
      expect(find.text('0987654321'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);

      // Verify metrics cards
      expect(find.text('Invoices'), findsOneWidget);
      expect(find.text('Commission'), findsOneWidget);
      expect(find.text('Tips'), findsOneWidget);
      expect(find.text('Total Estimated Earnings'), findsOneWidget);

      // Verify Invoices list displays Lan Hương's invoice
      expect(find.text('Lan Hương'), findsOneWidget);

      // Tap on invoice to expand details
      await tester.tap(find.text('Lan Hương'));
      await tester.pumpAndSettle();

      expect(find.text('Full Set Nail'), findsOneWidget);
      expect(find.text('Note: Khách tip thêm'), findsOneWidget);
    });
  });
}
