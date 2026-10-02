import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/customer_model.dart';
import '../../data/models/expense_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/services/database_service.dart';

class CsvExportService {
  final DatabaseService _dbService;

  CsvExportService(this._dbService);

  /// Helper to safely escape CSV field values (handles quotes, commas, newlines).
  static String _escapeCsvValue(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r')) {
      final escaped = value.replaceAll('"', '""');
      return '"$escaped"';
    }
    return value;
  }

  /// Format a DateTime into standard YYYY-MM-DD HH:mm:ss string.
  static String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  /// Builds a CSV string for Invoices with UTF-8 BOM.
  static String generateInvoicesCsv(List<Invoice> invoices) {
    final StringBuffer buffer = StringBuffer();
    // UTF-8 BOM for Excel compatibility
    buffer.write('\uFEFF');

    // Headers
    buffer.writeln(
      'Invoice ID,Customer ID,Customer Name,Services,Subtotal,Discount %,Final Total,Created Date,Session Start,Session End'
    );

    for (final inv in invoices) {
      final servicesSummary = inv.services
          .map((s) => '${s.serviceName} (\$${s.price.toStringAsFixed(2)})')
          .join('; ');

      final row = [
        _escapeCsvValue(inv.id),
        _escapeCsvValue(inv.customerId),
        _escapeCsvValue(inv.customerName),
        _escapeCsvValue(servicesSummary),
        inv.subtotal.toStringAsFixed(2),
        inv.discountPercent.toStringAsFixed(1),
        inv.finalTotal.toStringAsFixed(2),
        _escapeCsvValue(_formatDateTime(inv.createdAt)),
        _escapeCsvValue(_formatDateTime(inv.sessionStart)),
        _escapeCsvValue(_formatDateTime(inv.sessionEnd)),
      ];

      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  /// Builds a CSV string for Customers with UTF-8 BOM.
  static String generateCustomersCsv(List<Customer> customers) {
    final StringBuffer buffer = StringBuffer();
    buffer.write('\uFEFF');

    buffer.writeln('Customer ID,Name,Phone,Total Spent,Last Visit');

    for (final c in customers) {
      final row = [
        _escapeCsvValue(c.id),
        _escapeCsvValue(c.name),
        _escapeCsvValue(c.phone),
        c.totalSpent.toStringAsFixed(2),
        _escapeCsvValue(_formatDateTime(c.lastVisit)),
      ];

      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  /// Builds a CSV string for Expenses with UTF-8 BOM.
  static String generateExpensesCsv(List<Expense> expenses) {
    final StringBuffer buffer = StringBuffer();
    buffer.write('\uFEFF');

    buffer.writeln('Expense ID,Items,Total Cost,Note,Created Date');

    for (final e in expenses) {
      final itemsSummary = e.items
          .map((i) => '${i.description} (\$${i.cost.toStringAsFixed(2)})')
          .join('; ');

      final row = [
        _escapeCsvValue(e.id),
        _escapeCsvValue(itemsSummary),
        e.totalCost.toStringAsFixed(2),
        _escapeCsvValue(e.note),
        _escapeCsvValue(_formatDateTime(e.createdAt)),
      ];

      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  /// Builds a CSV string for Bookings with UTF-8 BOM.
  static String generateBookingsCsv(List<Booking> bookings) {
    final StringBuffer buffer = StringBuffer();
    buffer.write('\uFEFF');

    buffer.writeln('Booking ID,Title,Customer Name,Customer Phone,Start Time,End Time,Notes,Created Date');

    for (final b in bookings) {
      final row = [
        _escapeCsvValue(b.id),
        _escapeCsvValue(b.title),
        _escapeCsvValue(b.customerName ?? ''),
        _escapeCsvValue(b.customerPhone ?? ''),
        _escapeCsvValue(_formatDateTime(b.startTime)),
        _escapeCsvValue(_formatDateTime(b.endTime)),
        _escapeCsvValue(b.notes),
        _escapeCsvValue(_formatDateTime(b.createdAt)),
      ];

      buffer.writeln(row.join(','));
    }

    return buffer.toString();
  }

  /// Fetches data and exports selected categories to CSV files, launching the native share dialog.
  Future<void> exportSelectedData({
    required bool exportInvoices,
    required bool exportCustomers,
    required bool exportExpenses,
    required bool exportBookings,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final dateSuffix = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final List<XFile> filesToShare = [];

    if (exportInvoices) {
      final invoices = await _dbService.getInvoicesInRange(startDate: startDate, endDate: endDate);
      final csvString = generateInvoicesCsv(invoices);
      final file = File('${tempDir.path}/invoices_$dateSuffix.csv');
      await file.writeAsString(csvString);
      filesToShare.add(XFile(file.path, mimeType: 'text/csv'));
    }

    if (exportCustomers) {
      final customers = await _dbService.getCustomers();
      final csvString = generateCustomersCsv(customers);
      final file = File('${tempDir.path}/customers_$dateSuffix.csv');
      await file.writeAsString(csvString);
      filesToShare.add(XFile(file.path, mimeType: 'text/csv'));
    }

    if (exportExpenses) {
      final expenses = await _dbService.getExpensesInRange(startDate: startDate, endDate: endDate);
      final csvString = generateExpensesCsv(expenses);
      final file = File('${tempDir.path}/expenses_$dateSuffix.csv');
      await file.writeAsString(csvString);
      filesToShare.add(XFile(file.path, mimeType: 'text/csv'));
    }

    if (exportBookings) {
      final bookings = await _dbService.getBookingsInRange(startDate: startDate, endDate: endDate);
      final csvString = generateBookingsCsv(bookings);
      final file = File('${tempDir.path}/bookings_$dateSuffix.csv');
      await file.writeAsString(csvString);
      filesToShare.add(XFile(file.path, mimeType: 'text/csv'));
    }

    if (filesToShare.isNotEmpty) {
      await Share.shareXFiles(
        filesToShare,
        subject: 'Business Data CSV Export - $dateSuffix',
      );
    }
  }
}
