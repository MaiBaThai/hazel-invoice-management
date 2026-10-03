import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/src/pigeon/mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nms/core/providers/settings_provider.dart';
import 'package:nms/core/services/csv_export_service.dart';
import 'package:nms/data/models/invoice_model.dart';
import 'package:nms/data/services/database_service.dart';
import 'package:nms/features/invoice/widgets/invoice_detail_view.dart';
import 'package:provider/provider.dart';

void main() {
  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  group('Phase 7 - CSV Export & InvoiceDetailView Tests', () {
    test('generateInvoicesCsv correctly formats staff, tip, commission, notes columns', () {
      final invoice = Invoice(
        id: 'inv_101',
        customerId: 'cust_202',
        customerName: 'Alice Wonderland',
        staffNames: ['Bảo', 'Ngọc'],
        tip: 15.5,
        commissionPercent: 12.0,
        notes: 'Line 1\nLine 2 with "quotes" and, commas',
        services: [
          ServiceItem(serviceName: 'Hair Styling', price: 80.0),
        ],
        subtotal: 80.0,
        discountPercent: 10.0,
        finalTotal: 87.5,
        photoUrls: const [],
        createdAt: DateTime(2026, 10, 2, 10, 30),
      );

      final csv = CsvExportService.generateInvoicesCsv([invoice]);

      // Check header
      expect(csv, contains('Invoice ID,Customer ID,Customer Name,Staff,Services,Subtotal,Discount %,Tip,Commission %,Final Total,Notes,Created Date,Session Start,Session End'));

      // Check staff joined with semicolon
      expect(csv, contains('Bảo; Ngọc'));

      // Check tip, commission, final total
      expect(csv, contains('15.50,12.0,87.50'));

      // Check multiline note with quotes and commas is escaped properly
      expect(csv, contains('"Line 1\nLine 2 with ""quotes"" and, commas"'));
    });

    testWidgets('InvoiceDetailView renders staff, financial breakdown (subtotal, tip, commission), and notes', (tester) async {
      final fakeDb = DatabaseService(userId: 'test_p7', firestore: FakeFirebaseFirestore());
      final invoice = Invoice(
        id: 'inv_200',
        customerId: 'cust_300',
        customerName: 'Diana Prince',
        staffNames: ['Bảo', 'Ngọc'],
        tip: 10.0,
        commissionPercent: 15.0,
        notes: 'VIP customer, preferred coffee served.',
        services: [
          ServiceItem(serviceName: 'Gel Manicure', price: 50.0),
          ServiceItem(serviceName: 'Pedicure Deluxe', price: 40.0),
        ],
        subtotal: 90.0,
        discountPercent: 10.0,
        finalTotal: 91.0,
        photoUrls: const [],
        createdAt: DateTime(2026, 10, 2, 14, 0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            create: (_) => SettingsProvider(fakeDb),
            child: Scaffold(
              body: InvoiceDetailView(invoice: invoice),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify customer name
      expect(find.text('Diana Prince'), findsOneWidget);

      // Verify staff names
      expect(find.text('Staff: Bảo, Ngọc'), findsOneWidget);

      // Verify services
      expect(find.text('Gel Manicure'), findsOneWidget);
      expect(find.text('Pedicure Deluxe'), findsOneWidget);

      // Verify financial breakdown: Subtotal, Discount, Tip, Staff Commission, Total
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Discount'), findsOneWidget);
      expect(find.text('-10.0%'), findsOneWidget);
      expect(find.text('Tip'), findsOneWidget);
      expect(find.text(r'+$10'), findsOneWidget); // tip formatted with currency prefix
      expect(find.text('Staff Commission (15.0%)'), findsOneWidget);

      expect(find.text('Total Amount'), findsOneWidget);

      // Verify notes
      expect(find.text('NOTES'), findsOneWidget);
      expect(find.text('VIP customer, preferred coffee served.'), findsOneWidget);
    });
  });
}
