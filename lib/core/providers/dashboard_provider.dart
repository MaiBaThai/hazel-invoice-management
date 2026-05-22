import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/expense_model.dart';
import '../../data/services/database_service.dart';

enum DashboardRange {
  fourteenDays,
  thirtyDays,
  ninetyDays,
  ytd,
}

class ServiceSummary {
  final String name;
  final double totalRevenue;
  final int count;

  ServiceSummary({
    required this.name,
    required this.totalRevenue,
    required this.count,
  });
}

class _ServiceTemp {
  final String name;
  int count;
  double revenue;

  _ServiceTemp({
    required this.name,
    required this.count,
    required this.revenue,
  });
}

class DashboardProvider extends ChangeNotifier {
  DatabaseService _dbService;
  DashboardProvider(this._dbService);

  void updateDbService(DatabaseService newService) {
    debugPrint('DashboardProvider: updateDbService called with userId: ${newService.userId}');
    _dbService = newService;
    _resetStats();
    
    if (newService.userId != null) {
      loadDashboardData();
    }
  }

  void _resetStats() {
    _allInvoices = [];
    _allExpenses = [];
    _periodRevenue = 0;
    _periodExpenses = 0;
    _periodInvoiceCount = 0;
    _chartRevenueData = [];
    _chartExpenseData = [];
    _chartLabels = [];
    _topServices = [];
    _heatMapData = List.generate(7, (_) => List.filled(5, 0));
    _selectedRange = DashboardRange.fourteenDays;
    notifyListeners();
  }

  // Cached full data
  List<Invoice> _allInvoices = [];
  List<Expense> _allExpenses = [];

  // Selected range
  DashboardRange _selectedRange = DashboardRange.fourteenDays;
  DashboardRange get selectedRange => _selectedRange;

  set selectedRange(DashboardRange range) {
    if (_selectedRange != range) {
      _selectedRange = range;
      _calculateStats(_allInvoices, _allExpenses, DateTime.now());
      notifyListeners();
    }
  }

  // Computed metrics for selected range
  double _periodRevenue = 0;
  double _periodExpenses = 0;
  int _periodInvoiceCount = 0;

  double get periodRevenue => _periodRevenue;
  double get periodExpenses => _periodExpenses;
  double get periodNetProfit => _periodRevenue - _periodExpenses;
  double get periodProfitMargin => _periodRevenue > 0 ? ((_periodRevenue - _periodExpenses) / _periodRevenue) * 100 : 0;
  double get periodAverageTicket => _periodInvoiceCount > 0 ? _periodRevenue / _periodInvoiceCount : 0;
  int get periodInvoiceCount => _periodInvoiceCount;

  // Chart data
  List<double> _chartRevenueData = [];
  List<double> _chartExpenseData = [];
  List<String> _chartLabels = [];

  List<double> get chartRevenueData => _chartRevenueData;
  List<double> get chartExpenseData => _chartExpenseData;
  List<String> get chartLabels => _chartLabels;

  // Top 3 services
  List<ServiceSummary> _topServices = [];
  List<ServiceSummary> get topServices => _topServices;

  // Heat map data: 7 rows (Mon-Sun) x 5 columns (Time blocks)
  List<List<int>> _heatMapData = List.generate(7, (_) => List.filled(5, 0));
  List<List<int>> get heatMapData => _heatMapData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch 365 days of data to cover all analytics ranges
      final fetchSince = DateTime.now().subtract(const Duration(days: 365));
      
      final results = await Future.wait([
        _dbService.getInvoicesSince(fetchSince),
        _dbService.getExpensesSince(fetchSince),
      ]);

      _allInvoices = results[0] as List<Invoice>;
      _allExpenses = results[1] as List<Expense>;
      
      _calculateStats(_allInvoices, _allExpenses, DateTime.now());
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int _getTimeSlotIndex(int hour) {
    if (hour < 11) return 0; // Morning (before 11 AM)
    if (hour < 13) return 1; // Midday (11 AM - 1 PM)
    if (hour < 15) return 2; // Early PM (1 PM - 3 PM)
    if (hour < 17) return 3; // Late PM (3 PM - 5 PM)
    return 4;                // Evening (5 PM onwards)
  }

  void _calculateStats(List<Invoice> invoices, List<Expense> expenses, DateTime now) {
    final todayDate = DateTime(now.year, now.month, now.day);
    
    // 1. Filter data based on selected range
    List<Invoice> filteredInvoices = [];
    List<Expense> filteredExpenses = [];

    DateTime startLimit;
    switch (_selectedRange) {
      case DashboardRange.fourteenDays:
        startLimit = todayDate.subtract(const Duration(days: 13));
        break;
      case DashboardRange.thirtyDays:
        startLimit = todayDate.subtract(const Duration(days: 29));
        break;
      case DashboardRange.ninetyDays:
        startLimit = todayDate.subtract(const Duration(days: 89));
        break;
      case DashboardRange.ytd:
        startLimit = DateTime(now.year, 1, 1);
        break;
    }

    for (var invoice in invoices) {
      final invDate = DateTime(invoice.createdAt.year, invoice.createdAt.month, invoice.createdAt.day);
      if (!invDate.isBefore(startLimit) && !invDate.isAfter(todayDate)) {
        filteredInvoices.add(invoice);
      }
    }

    for (var expense in expenses) {
      final expDate = DateTime(expense.createdAt.year, expense.createdAt.month, expense.createdAt.day);
      if (!expDate.isBefore(startLimit) && !expDate.isAfter(todayDate)) {
        filteredExpenses.add(expense);
      }
    }

    // 2. Sum up total period values
    _periodRevenue = filteredInvoices.fold(0.0, (sum, item) => sum + item.finalTotal);
    _periodExpenses = filteredExpenses.fold(0.0, (sum, item) => sum + item.totalCost);
    _periodInvoiceCount = filteredInvoices.length;

    // 3. Calculate chart data points and labels
    _chartRevenueData = [];
    _chartExpenseData = [];
    _chartLabels = [];

    if (_selectedRange == DashboardRange.fourteenDays) {
      // 14 Days: Daily representation
      final daysCount = 14;
      _chartRevenueData = List.filled(daysCount, 0.0);
      _chartExpenseData = List.filled(daysCount, 0.0);
      _chartLabels = List.generate(daysCount, (index) {
        final d = todayDate.subtract(Duration(days: daysCount - 1 - index));
        return DateFormat('d/M').format(d);
      });

      for (var inv in filteredInvoices) {
        final daysAgo = todayDate.difference(DateTime(inv.createdAt.year, inv.createdAt.month, inv.createdAt.day)).inDays;
        if (daysAgo >= 0 && daysAgo < daysCount) {
          _chartRevenueData[daysCount - 1 - daysAgo] += inv.finalTotal;
        }
      }
      for (var exp in filteredExpenses) {
        final daysAgo = todayDate.difference(DateTime(exp.createdAt.year, exp.createdAt.month, exp.createdAt.day)).inDays;
        if (daysAgo >= 0 && daysAgo < daysCount) {
          _chartExpenseData[daysCount - 1 - daysAgo] += exp.totalCost;
        }
      }

    } else if (_selectedRange == DashboardRange.thirtyDays || _selectedRange == DashboardRange.ninetyDays) {
      // 30 Days & 90 Days: Grouped by 7-day windows (weeks)
      final totalDays = _selectedRange == DashboardRange.thirtyDays ? 28 : 91; // Round to whole weeks
      final weeksCount = totalDays ~/ 7;

      _chartRevenueData = List.filled(weeksCount, 0.0);
      _chartExpenseData = List.filled(weeksCount, 0.0);
      _chartLabels = List.generate(weeksCount, (index) {
        final start = todayDate.subtract(Duration(days: totalDays - 1 - (index * 7)));
        return DateFormat('d/M').format(start);
      });

      for (var inv in filteredInvoices) {
        final daysAgo = todayDate.difference(DateTime(inv.createdAt.year, inv.createdAt.month, inv.createdAt.day)).inDays;
        if (daysAgo >= 0 && daysAgo < totalDays) {
          final weekIndex = (totalDays - 1 - daysAgo) ~/ 7;
          if (weekIndex >= 0 && weekIndex < weeksCount) {
            _chartRevenueData[weekIndex] += inv.finalTotal;
          }
        }
      }
      for (var exp in filteredExpenses) {
        final daysAgo = todayDate.difference(DateTime(exp.createdAt.year, exp.createdAt.month, exp.createdAt.day)).inDays;
        if (daysAgo >= 0 && daysAgo < totalDays) {
          final weekIndex = (totalDays - 1 - daysAgo) ~/ 7;
          if (weekIndex >= 0 && weekIndex < weeksCount) {
            _chartExpenseData[weekIndex] += exp.totalCost;
          }
        }
      }

    } else if (_selectedRange == DashboardRange.ytd) {
      // YTD: Monthly representation of current year
      final monthsCount = now.month;
      _chartRevenueData = List.filled(monthsCount, 0.0);
      _chartExpenseData = List.filled(monthsCount, 0.0);
      
      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      _chartLabels = List.generate(monthsCount, (index) => monthNames[index]);

      for (var inv in filteredInvoices) {
        if (inv.createdAt.year == now.year) {
          final mIndex = inv.createdAt.month - 1;
          if (mIndex >= 0 && mIndex < monthsCount) {
            _chartRevenueData[mIndex] += inv.finalTotal;
          }
        }
      }
      for (var exp in filteredExpenses) {
        if (exp.createdAt.year == now.year) {
          final mIndex = exp.createdAt.month - 1;
          if (mIndex >= 0 && mIndex < monthsCount) {
            _chartExpenseData[mIndex] += exp.totalCost;
          }
        }
      }
    }

    // 4. Calculate top 3 services
    final Map<String, _ServiceTemp> serviceMap = {};
    for (var invoice in filteredInvoices) {
      for (var item in invoice.services) {
        final name = item.serviceName.trim();
        if (name.isEmpty) continue;
        final key = name.toLowerCase();
        if (serviceMap.containsKey(key)) {
          serviceMap[key]!.count += 1;
          serviceMap[key]!.revenue += item.price;
        } else {
          serviceMap[key] = _ServiceTemp(name: name, count: 1, revenue: item.price);
        }
      }
    }

    final sorted = serviceMap.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    
    _topServices = sorted.take(3).map((s) => ServiceSummary(
      name: s.name,
      totalRevenue: s.revenue,
      count: s.count,
    )).toList();

    // 5. Calculate Weekly Heat Map data (7 days x 5 slots)
    _heatMapData = List.generate(7, (_) => List.filled(5, 0));
    for (var inv in filteredInvoices) {
      final weekdayIndex = inv.createdAt.weekday - 1; // Monday (0) - Sunday (6)
      if (weekdayIndex >= 0 && weekdayIndex < 7) {
        final slotIndex = _getTimeSlotIndex(inv.createdAt.hour);
        _heatMapData[weekdayIndex][slotIndex]++;
      }
    }
  }

  Map<String, dynamic> getDetailsForIndex(int index) {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    List<Invoice> invoices = [];
    List<Expense> expenses = [];
    DateTime date = todayDate;

    if (_selectedRange == DashboardRange.fourteenDays) {
      final targetDate = todayDate.subtract(Duration(days: 13 - index));
      date = targetDate;
      invoices = _allInvoices.where((inv) {
        final d = inv.createdAt;
        return d.year == targetDate.year && d.month == targetDate.month && d.day == targetDate.day;
      }).toList();
      expenses = _allExpenses.where((exp) {
        final d = exp.createdAt;
        return d.year == targetDate.year && d.month == targetDate.month && d.day == targetDate.day;
      }).toList();

    } else if (_selectedRange == DashboardRange.thirtyDays || _selectedRange == DashboardRange.ninetyDays) {
      final totalDays = _selectedRange == DashboardRange.thirtyDays ? 28 : 91;
      final start = todayDate.subtract(Duration(days: totalDays - 1 - (index * 7)));
      final end = start.add(const Duration(days: 6));
      date = start; // represent by week start
      invoices = _allInvoices.where((inv) {
        final d = DateTime(inv.createdAt.year, inv.createdAt.month, inv.createdAt.day);
        return !d.isBefore(start) && !d.isAfter(end);
      }).toList();
      expenses = _allExpenses.where((exp) {
        final d = DateTime(exp.createdAt.year, exp.createdAt.month, exp.createdAt.day);
        return !d.isBefore(start) && !d.isAfter(end);
      }).toList();

    } else if (_selectedRange == DashboardRange.ytd) {
      date = DateTime(now.year, index + 1, 1);
      invoices = _allInvoices.where((inv) {
        return inv.createdAt.year == now.year && inv.createdAt.month == (index + 1);
      }).toList();
      expenses = _allExpenses.where((exp) {
        return exp.createdAt.year == now.year && exp.createdAt.month == (index + 1);
      }).toList();
    }

    invoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    expenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return {
      'invoices': invoices,
      'expenses': expenses,
      'date': date,
    };
  }
}

