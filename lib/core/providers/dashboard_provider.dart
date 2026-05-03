import 'package:flutter/material.dart';
import '../../data/models/invoice_model.dart';
import '../../data/services/database_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  double _todayRevenue = 0;
  double _monthRevenue = 0;
  double _yearRevenue = 0;
  
  // Chart data: List of daily revenues for the last 7 days (index 0 is today - 6, index 6 is today)
  List<double> _last7DaysRevenue = List.filled(7, 0.0);
  
  // Raw invoices for the last 7 days, grouped by index (0-6)
  List<List<Invoice>> _dailyInvoices = List.generate(7, (_) => []);
  
  bool _isLoading = false;

  // Getters
  double get todayRevenue => _todayRevenue;
  double get monthRevenue => _monthRevenue;
  double get yearRevenue => _yearRevenue;
  List<double> get last7DaysRevenue => _last7DaysRevenue;
  List<List<Invoice>> get dailyInvoices => _dailyInvoices;
  bool get isLoading => _isLoading;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final startOfYear = DateTime(now.year, 1, 1);
      final sevenDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      
      final fetchSince = startOfYear.isBefore(sevenDaysAgo) ? startOfYear : sevenDaysAgo;
      
      final invoices = await _dbService.getInvoicesSince(fetchSince);
      
      _calculateStats(invoices, now);
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _calculateStats(List<Invoice> invoices, DateTime now) {
    _todayRevenue = 0;
    _monthRevenue = 0;
    _yearRevenue = 0;
    _last7DaysRevenue = List.filled(7, 0.0);
    _dailyInvoices = List.generate(7, (_) => []);

    final todayDate = DateTime(now.year, now.month, now.day);
    
    for (var invoice in invoices) {
      final date = invoice.createdAt;
      final invoiceDate = DateTime(date.year, date.month, date.day);
      
      // Year stat
      if (date.year == now.year) {
        _yearRevenue += invoice.finalTotal;
      }
      
      // Month stat
      if (date.year == now.year && date.month == now.month) {
        _monthRevenue += invoice.finalTotal;
      }
      
      // Today stat
      if (invoiceDate == todayDate) {
        _todayRevenue += invoice.finalTotal;
      }
      
      // 7 Days Chart stat
      final differenceInDays = todayDate.difference(invoiceDate).inDays;
      if (differenceInDays >= 0 && differenceInDays < 7) {
        final index = 6 - differenceInDays;
        _last7DaysRevenue[index] += invoice.finalTotal;
        _dailyInvoices[index].add(invoice);
      }
    }

    // Sort invoices within each day by creation time (newest first)
    for (var list in _dailyInvoices) {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }
}
