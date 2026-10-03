import 'package:flutter_test/flutter_test.dart';
import 'package:nms/core/providers/staff_provider.dart';
import 'package:nms/core/providers/invoice_provider.dart';
import 'package:nms/data/models/staff_model.dart';
import 'package:nms/data/models/invoice_model.dart';
import 'package:nms/data/models/customer_model.dart';
import 'package:nms/data/services/database_service.dart';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

class MockDatabaseService extends DatabaseService {
  final List<Staff> mockStaff = [];
  final List<Invoice> mockInvoices = [];

  MockDatabaseService()
      : super(
          userId: 'test_user',
          firestore: FakeFirebaseFirestore(),
        );

  @override
  Future<List<Staff>> getStaffList() async {
    return List.from(mockStaff);
  }

  @override
  Future<Staff?> getStaff(String staffId) async {
    try {
      return mockStaff.firstWhere((s) => s.id == staffId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> addStaff(Staff staff) async {
    final id = 'staff_${mockStaff.length + 1}';
    mockStaff.add(staff.copyWith(id: id));
    return id;
  }

  @override
  Future<void> updateStaff(Staff staff) async {
    final idx = mockStaff.indexWhere((s) => s.id == staff.id);
    if (idx != -1) {
      mockStaff[idx] = staff;
    }
  }

  @override
  Future<void> deleteStaff(String staffId) async {
    mockStaff.removeWhere((s) => s.id == staffId);
  }

  @override
  Future<List<Invoice>> getStaffInvoices(String staffName) async {
    return mockInvoices.where((inv) => inv.staffNames.contains(staffName)).toList();
  }
}

void main() {
  group('Phase 2 State Management Tests', () {
    test('StaffProvider: loads, adds, searches, and computes earnings correctly', () async {
      final mockDb = MockDatabaseService();
      final provider = StaffProvider(mockDb);

      // 1. Add staff
      final id1 = await provider.addStaff(name: 'Bảo', phone: '0901111111', defaultCommissionPercent: 10.0);
      final id2 = await provider.addStaff(name: 'Ngọc', phone: '0902222222', defaultCommissionPercent: 15.0);

      expect(provider.allStaff.length, 2);
      expect(provider.activeStaff.length, 2);

      // 2. Search staff
      provider.searchStaff('bao');
      expect(provider.searchResults.length, 1);
      expect(provider.searchResults.first.name, 'Bảo');

      // 3. Mock invoices served by Bao and Ngoc
      // Invoice 1: served only by Bao. Subtotal: 100, Discount: 0%, Commission: 10% (10.0), Tip: 20.0
      mockDb.mockInvoices.add(Invoice(
        id: 'inv_1',
        customerId: 'c1',
        customerName: 'Cust 1',
        services: [ServiceItem(serviceName: 'Nail', price: 100.0)],
        subtotal: 100.0,
        discountPercent: 0.0,
        finalTotal: 100.0,
        photoUrls: [],
        createdAt: DateTime.now(),
        staffNames: ['Bảo'],
        commissionPercent: 10.0,
        tip: 20.0,
      ));

      // Invoice 2: served by BOTH Bao & Ngoc (shared 50/50).
      // Subtotal: 200, Discount: 10% -> 180 commissionable. Commission: 10% -> total 18.0 (9.0 each). Tip: 30.0 (15.0 each).
      mockDb.mockInvoices.add(Invoice(
        id: 'inv_2',
        customerId: 'c2',
        customerName: 'Cust 2',
        services: [ServiceItem(serviceName: 'Combo', price: 200.0)],
        subtotal: 200.0,
        discountPercent: 10.0,
        finalTotal: 180.0,
        photoUrls: [],
        createdAt: DateTime.now(),
        staffNames: ['Bảo', 'Ngọc'],
        commissionPercent: 10.0,
        tip: 30.0,
      ));

      // 4. Load Bao details
      await provider.loadStaffDetails(id1!);
      expect(provider.selectedStaff?.name, 'Bảo');
      expect(provider.staffInvoices.length, 2);

      // Bao's commission: 10.0 (from inv 1) + 9.0 (from inv 2) = 19.0
      expect(provider.staffTotalCommission, 19.0);
      // Bao's tip: 20.0 (from inv 1) + 15.0 (from inv 2) = 35.0
      expect(provider.staffTotalTips, 35.0);
      // Bao's total earnings: 19.0 + 35.0 = 54.0
      expect(provider.staffTotalEarnings, 54.0);
    });

    test('InvoiceProvider: staff selection, tip, commission, and notes state', () {
      final mockDb = MockDatabaseService();
      final provider = InvoiceProvider(mockDb);

      // Initially empty
      expect(provider.selectedStaffNames, isEmpty);
      expect(provider.tip, 0.0);
      expect(provider.commissionPercent, 0.0);
      expect(provider.notes, '');

      // Toggle first staff -> auto-fills default commission %
      provider.toggleStaffName('Bảo', defaultCommission: 12.0);
      expect(provider.selectedStaffNames, ['Bảo']);
      expect(provider.commissionPercent, 12.0);

      // Toggle second staff
      provider.toggleStaffName('Ngọc', defaultCommission: 15.0);
      expect(provider.selectedStaffNames, ['Bảo', 'Ngọc']);
      // Commission % remains 12.0 because already set
      expect(provider.commissionPercent, 12.0);

      // Set tip and notes
      provider.setTip(25.0);
      provider.setNotes('Khách dặn nhẹ tay');
      expect(provider.tip, 25.0);
      expect(provider.notes, 'Khách dặn nhẹ tay');

      // Add service to test estimated commission
      provider.addService();
      provider.updateService(0, 'Service 1', 100.0);
      provider.setDiscount(10.0); // 90.0 net

      // 90 * 12% = 10.8
      expect(provider.estimatedCommissionAmount, closeTo(10.8, 0.001));

      // Test loadInvoiceForEditing
      final testInvoice = Invoice(
        id: 'edit_inv',
        customerId: 'cust_x',
        customerName: 'Customer X',
        services: [ServiceItem(serviceName: 'Hair', price: 80.0)],
        subtotal: 80.0,
        discountPercent: 5.0,
        finalTotal: 76.0,
        photoUrls: [],
        createdAt: DateTime.now(),
        staffNames: ['Mai'],
        tip: 10.0,
        commissionPercent: 15.0,
        notes: 'Ghi chú sửa đổi',
      );

      provider.loadInvoiceForEditing(testInvoice, Customer(id: 'cust_x', name: 'Customer X', phone: '090'));
      expect(provider.isEditing, isTrue);
      expect(provider.editingInvoiceId, 'edit_inv');
      expect(provider.tip, 10.0);
      expect(provider.commissionPercent, 15.0);
      expect(provider.notes, 'Ghi chú sửa đổi');

      // Reset restores to empty
      provider.reset();
      expect(provider.isEditing, isFalse);
      expect(provider.editingInvoiceId, isNull);
      expect(provider.selectedStaffNames, isEmpty);
      expect(provider.tip, 0.0);
      expect(provider.commissionPercent, 0.0);
      expect(provider.notes, '');

      // Toggle staff then deselect all resets commission to 0
      provider.toggleStaffName('Bảo', defaultCommission: 15.0);
      expect(provider.commissionPercent, 15.0);
      provider.toggleStaffName('Bảo');
      expect(provider.selectedStaffNames, isEmpty);
      expect(provider.commissionPercent, 0.0);
    });
  });
}
