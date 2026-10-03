import 'package:flutter_test/flutter_test.dart';
import 'package:nms/data/models/staff_model.dart';
import 'package:nms/data/models/invoice_model.dart';
import 'package:nms/data/models/customer_note_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('Phase 1 Models Test', () {
    test('Staff model: serialization and deserialization', () {
      final now = DateTime.now();
      final staff = Staff(
        id: 'staff_1',
        name: 'Bảo',
        phone: '0901234567',
        defaultCommissionPercent: 15.0,
        createdAt: now,
        isActive: true,
      );

      final map = staff.toMap();
      expect(map['name'], 'Bảo');
      expect(map['name_lowercase'], 'bảo');
      expect(map['phone'], '0901234567');
      expect(map['default_commission_percent'], 15.0);
      expect(map['is_active'], true);

      final fromMap = Staff.fromMap('staff_1', {
        'name': 'Bảo',
        'phone': '0901234567',
        'default_commission_percent': 15,
        'created_at': Timestamp.fromDate(now),
        'is_active': true,
      });

      expect(fromMap.id, 'staff_1');
      expect(fromMap.name, 'Bảo');
      expect(fromMap.defaultCommissionPercent, 15.0);
      expect(fromMap.isActive, true);
    });

    test('Invoice model: backward compatibility with legacy maps without tip/commission/staff/notes', () {
      final now = DateTime.now();
      final legacyMap = {
        'customer_id': 'cust_1',
        'customer_name': 'Mai Ba Thai',
        'services': [
          {'service_name': 'Manicure', 'price': 50.0}
        ],
        'subtotal': 50.0,
        'discount_percent': 10.0,
        'final_total': 45.0,
        'photoUrls': <String>[],
        'created_at': Timestamp.fromDate(now),
      };

      final invoice = Invoice.fromMap('inv_1', legacyMap);
      expect(invoice.id, 'inv_1');
      expect(invoice.tip, 0.0);
      expect(invoice.commissionPercent, 0.0);
      expect(invoice.staffNames, isEmpty);
      expect(invoice.notes, '');

      // Verify serialization of new invoice
      final newInvoice = invoice.copyWith(
        tip: 20.0,
        commissionPercent: 10.0,
        staffNames: ['Bảo', 'Ngọc'],
        notes: 'Khách thích sơn bóng',
      );

      final map = newInvoice.toMap();
      expect(map['tip'], 20.0);
      expect(map['commission_percent'], 10.0);
      expect(map['staff_names'], ['Bảo', 'Ngọc']);
      expect(map['notes'], 'Khách thích sơn bóng');

      final fromNewMap = Invoice.fromMap('inv_1', map);
      expect(fromNewMap.tip, 20.0);
      expect(fromNewMap.commissionPercent, 10.0);
      expect(fromNewMap.staffNames, ['Bảo', 'Ngọc']);
      expect(fromNewMap.notes, 'Khách thích sơn bóng');
    });

    test('CustomerNote model: serialization and deserialization', () {
      final now = DateTime.now();
      final note = CustomerNote(
        id: 'note_1',
        content: 'Khách hay uống trà đào',
        createdAt: now,
      );

      final map = note.toMap();
      expect(map['content'], 'Khách hay uống trà đào');
      expect(map['updated_at'], isNull);

      final fromMap = CustomerNote.fromMap('note_1', {
        'content': 'Khách hay uống trà đào',
        'created_at': Timestamp.fromDate(now),
      });

      expect(fromMap.id, 'note_1');
      expect(fromMap.content, 'Khách hay uống trà đào');
    });
  });
}
