import 'package:flutter_test/flutter_test.dart';
import 'package:nms/core/services/csv_export_service.dart';
import 'package:nms/data/models/booking_model.dart';
import 'package:nms/data/models/customer_model.dart';
import 'package:nms/data/models/expense_model.dart';
import 'package:nms/data/models/invoice_model.dart';

void main() {
  group('CsvExportService Unit Tests', () {
    test('generateInvoicesCsv includes UTF-8 BOM and correct headers/escaping', () {
      final invoices = [
        Invoice(
          id: 'inv_1',
          customerId: 'cust_1',
          customerName: 'Mary Jane, "VIP"',
          staffNames: ['Bảo', 'Ngọc'],
          tip: 5.0,
          commissionPercent: 10.0,
          notes: 'Customer requested French design, VIP seat',
          services: [
            ServiceItem(serviceName: 'Gel Manicure', price: 35.0),
            ServiceItem(serviceName: 'Nail Art', price: 15.0),
          ],
          subtotal: 50.0,
          discountPercent: 10.0,
          finalTotal: 50.0,
          photoUrls: [],
          createdAt: DateTime(2026, 8, 24, 14, 30),
        ),
      ];

      final csv = CsvExportService.generateInvoicesCsv(invoices);

      // Verify UTF-8 BOM
      expect(csv.startsWith('\uFEFF'), isTrue);

      // Verify headers
      expect(csv, contains('Invoice ID,Customer ID,Customer Name,Staff,Services,Subtotal,Discount %,Tip,Commission %,Final Total,Notes,Created Date,Session Start,Session End'));

      // Verify escaping quotes in customer name
      expect(csv, contains('"Mary Jane, ""VIP"""'));

      // Verify staff names joined
      expect(csv, contains('Bảo; Ngọc'));

      // Verify tip and commission
      expect(csv, contains('5.00,10.0,50.00'));

      // Verify notes escaped
      expect(csv, contains('"Customer requested French design, VIP seat"'));

      // Verify formatted services
      expect(csv, contains('Gel Manicure (\$35.00); Nail Art (\$15.00)'));
    });

    test('generateCustomersCsv formats customer rows accurately', () {
      final customers = [
        Customer(
          id: 'cust_1',
          name: 'Jane Doe',
          phone: '+123456789',
          totalSpent: 120.50,
          lastVisit: DateTime(2026, 8, 20, 10, 0),
        ),
      ];

      final csv = CsvExportService.generateCustomersCsv(customers);
      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv, contains('Customer ID,Name,Phone,Total Spent,Last Visit'));
      expect(csv, contains('cust_1,Jane Doe,+123456789,120.50,2026-08-20 10:00:00'));
    });

    test('generateExpensesCsv formats expense rows accurately', () {
      final expenses = [
        Expense(
          id: 'exp_1',
          items: [
            ExpenseItem(description: 'Acetone Bottle', cost: 12.0),
          ],
          totalCost: 12.0,
          note: 'Bought from distributor',
          createdAt: DateTime(2026, 8, 22, 15, 45),
        ),
      ];

      final csv = CsvExportService.generateExpensesCsv(expenses);
      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv, contains('Expense ID,Items,Total Cost,Note,Created Date'));
      expect(csv, contains('exp_1,Acetone Bottle (\$12.00),12.00,Bought from distributor,2026-08-22 15:45:00'));
    });

    test('generateBookingsCsv formats booking rows accurately', () {
      final bookings = [
        Booking(
          id: 'book_1',
          title: 'Full Set Gel',
          customerName: 'Sarah Smith',
          customerPhone: '555-0199',
          startTime: DateTime(2026, 8, 25, 10, 0),
          endTime: DateTime(2026, 8, 25, 11, 30),
          notes: 'Wants french tip',
          createdAt: DateTime(2026, 8, 24, 9, 0),
          updatedAt: DateTime(2026, 8, 24, 9, 0),
        ),
      ];

      final csv = CsvExportService.generateBookingsCsv(bookings);
      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv, contains('Booking ID,Title,Customer Name,Customer Phone,Start Time,End Time,Notes,Created Date'));
      expect(csv, contains('book_1,Full Set Gel,Sarah Smith,555-0199,2026-08-25 10:00:00,2026-08-25 11:30:00,Wants french tip,2026-08-24 09:00:00'));
    });
  });
}
