import 'package:flutter/material.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/expense_model.dart';
import '../../data/services/database_service.dart';

class DashboardProvider extends ChangeNotifier {
  DatabaseService _dbService;
  DashboardProvider(this._dbService);

  void updateDbService(DatabaseService newService) {
    debugPrint('DashboardProvider: updateDbService called with userId: ${newService.userId}');
    _dbService = newService;
    _resetStats();
    
    // Only load if we have a valid userId
    if (newService.userId != null) {
      loadDashboardData();
    }
  }

  void _resetStats() {
    _todayRevenue = 0;
    _monthRevenue = 0;
    _yearRevenue = 0;
    _todayExpenses = 0;
    _monthExpenses = 0;
    _yearExpenses = 0;
    _last7DaysRevenue = List.filled(7, 0.0);
    _last7DaysExpenses = List.filled(7, 0.0);
    _dailyInvoices = List.generate(7, (_) => []);
    _dailyExpenses = List.generate(7, (_) => []);
    notifyListeners();
  }

  double _todayRevenue = 0;
  double _monthRevenue = 0;
  double _yearRevenue = 0;

  double _todayExpenses = 0;
  double _monthExpenses = 0;
  double _yearExpenses = 0;
  
  // Chart data: List of daily values for the last 7 days (index 0 is today - 6, index 6 is today)
  List<double> _last7DaysRevenue = List.filled(7, 0.0);
  List<double> _last7DaysExpenses = List.filled(7, 0.0);
  
  // Raw invoices and expenses for the last 7 days, grouped by index (0-6)
  List<List<Invoice>> _dailyInvoices = List.generate(7, (_) => []);
  List<List<Expense>> _dailyExpenses = List.generate(7, (_) => []);
  
  bool _isLoading = false;

  // Getters
  double get todayRevenue => _todayRevenue;
  double get monthRevenue => _monthRevenue;
  double get yearRevenue => _yearRevenue;

  double get todayExpenses => _todayExpenses;
  double get monthExpenses => _monthExpenses;
  double get yearExpenses => _yearExpenses;

  double get monthProfit => _monthRevenue - _monthExpenses;
  double get profitMargin => _monthRevenue > 0 ? ((_monthRevenue - _monthExpenses) / _monthRevenue) * 100 : 0;

  List<double> get last7DaysRevenue => _last7DaysRevenue;
  List<double> get last7DaysExpenses => _last7DaysExpenses;
  List<List<Invoice>> get dailyInvoices => _dailyInvoices;
  List<List<Expense>> get dailyExpenses => _dailyExpenses;
  bool get isLoading => _isLoading;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final startOfYear = DateTime(now.year, 1, 1);
      final sevenDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      
      final fetchSince = startOfYear.isBefore(sevenDaysAgo) ? startOfYear : sevenDaysAgo;
      
      final results = await Future.wait([
        _dbService.getInvoicesSince(fetchSince),
        _dbService.getExpensesSince(fetchSince),
      ]);

      final invoices = results[0] as List<Invoice>;
      final expenses = results[1] as List<Expense>;
      
      _calculateStats(invoices, expenses, now);
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _calculateStats(List<Invoice> invoices, List<Expense> expenses, DateTime now) {
    _todayRevenue = 0;
    _monthRevenue = 0;
    _yearRevenue = 0;
    _todayExpenses = 0;
    _monthExpenses = 0;
    _yearExpenses = 0;
    _last7DaysRevenue = List.filled(7, 0.0);
    _last7DaysExpenses = List.filled(7, 0.0);
    _dailyInvoices = List.generate(7, (_) => []);
    _dailyExpenses = List.generate(7, (_) => []);

    final todayDate = DateTime(now.year, now.month, now.day);
    
    // Process Invoices
    for (var invoice in invoices) {
      final date = invoice.createdAt;
      final invoiceDate = DateTime(date.year, date.month, date.day);
      
      if (date.year == now.year) {
        _yearRevenue += invoice.finalTotal;
        if (date.month == now.month) {
          _monthRevenue += invoice.finalTotal;
        }
      }
      
      if (invoiceDate == todayDate) {
        _todayRevenue += invoice.finalTotal;
      }
      
      final differenceInDays = todayDate.difference(invoiceDate).inDays;
      if (differenceInDays >= 0 && differenceInDays < 7) {
        final index = 6 - differenceInDays;
        _last7DaysRevenue[index] += invoice.finalTotal;
        _dailyInvoices[index].add(invoice);
      }
    }

    // Process Expenses
    for (var expense in expenses) {
      final date = expense.createdAt;
      final expenseDate = DateTime(date.year, date.month, date.day);
      
      if (date.year == now.year) {
        _yearExpenses += expense.totalCost;
        if (date.month == now.month) {
          _monthExpenses += expense.totalCost;
        }
      }
      
      if (expenseDate == todayDate) {
        _todayExpenses += expense.totalCost;
      }
      
      final differenceInDays = todayDate.difference(expenseDate).inDays;
      if (differenceInDays >= 0 && differenceInDays < 7) {
        final index = 6 - differenceInDays;
        _last7DaysExpenses[index] += expense.totalCost;
        _dailyExpenses[index].add(expense);
      }
    }

    // Sort invoices
    for (var list in _dailyInvoices) {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    for (var list in _dailyExpenses) {
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }
}
