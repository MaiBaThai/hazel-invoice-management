import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../data/models/app_settings_model.dart';
import 'widgets/daily_details_dialog.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final businessConfig = settingsProvider.settings?.businessConfig ?? BusinessConfig(businessName: 'Hazel Nails', currencySymbol: 'k');
    
    String formatCurrency(num amount) {
      final formatted = NumberFormat.decimalPattern().format(amount);
      return businessConfig.isPrefix ? '${businessConfig.currencySymbol}$formatted' : '$formatted${businessConfig.currencySymbol}';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.loadDashboardData(),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.loadDashboardData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Revenue Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 12),
                    const SizedBox(height: 12),
                    _buildRevenueCards(provider, formatCurrency),
                    const SizedBox(height: 24),
                    const Text('Expenses Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 12),
                    _buildExpenseCards(provider, formatCurrency),
                    const SizedBox(height: 24),
                    _buildProfitCard(provider, formatCurrency),
                    const SizedBox(height: 32),
                    const Text('Last 7 Days Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Revenue vs Expenses', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 16),
                    _buildChart(provider, formatCurrency),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRevenueCards(DashboardProvider provider, String Function(num) formatCurrency) {
    return Row(
      children: [
        Expanded(child: _SummaryCard(title: 'Today', amount: formatCurrency(provider.todayRevenue), color: Colors.pink)),
        const SizedBox(width: 8),
        Expanded(child: _SummaryCard(title: 'This Month', amount: formatCurrency(provider.monthRevenue), color: Colors.pink)),
        const SizedBox(width: 8),
        Expanded(child: _SummaryCard(title: 'This Year', amount: formatCurrency(provider.yearRevenue), color: Colors.pink)),
      ],
    );
  }

  Widget _buildExpenseCards(DashboardProvider provider, String Function(num) formatCurrency) {
    return Row(
      children: [
        Expanded(child: _SummaryCard(title: 'Today', amount: formatCurrency(provider.todayExpenses), color: Colors.orange)),
        const SizedBox(width: 8),
        Expanded(child: _SummaryCard(title: 'This Month', amount: formatCurrency(provider.monthExpenses), color: Colors.orange)),
        const SizedBox(width: 8),
        Expanded(child: _SummaryCard(title: 'This Year', amount: formatCurrency(provider.yearExpenses), color: Colors.orange)),
      ],
    );
  }

  Widget _buildProfitCard(DashboardProvider provider, String Function(num) formatCurrency) {
    final profit = provider.monthProfit;
    final isProfit = profit >= 0;
    final color = isProfit ? Colors.green : Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            'MONTHLY NET PROFIT',
            style: TextStyle(color: color.withOpacity(0.8), fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(
            '${isProfit ? "+" : ""}${formatCurrency(profit)}',
            style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isProfit ? Icons.trending_up : Icons.trending_down, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                '${provider.profitMargin.toStringAsFixed(1)}% Margin',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isProfit ? 'PROFITABLE' : 'LOSS',
                  style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart(DashboardProvider provider, String Function(num) formatCurrency) {
    final revenueData = provider.last7DaysRevenue;
    final expenseData = provider.last7DaysExpenses;
    
    double maxY = 0;
    for (var d in revenueData) if (d > maxY) maxY = d;
    for (var d in expenseData) if (d > maxY) maxY = d;
    
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100;

    return AspectRatio(
      aspectRatio: 1.5,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.grey.withOpacity(0.03),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final isRevenue = rodIndex == 0;
                    return BarTooltipItem(
                      '${isRevenue ? "Revenue" : "Expense"}\n${formatCurrency(rod.toY)}',
                      TextStyle(color: rod.color, fontWeight: FontWeight.bold),
                    );
                  },
                ),
                touchCallback: (FlTouchEvent event, barTouchResponse) {
                  if (event is FlTapUpEvent && barTouchResponse != null && barTouchResponse.spot != null) {
                    final index = barTouchResponse.spot!.touchedBarGroupIndex;
                    final invoices = provider.dailyInvoices[index];
                    final expenses = provider.dailyExpenses[index];
                    final date = DateTime.now().subtract(Duration(days: 6 - index));
                    showDialog(
                      context: context,
                      builder: (context) => DailyDetailsDialog(
                        invoices: invoices,
                        expenses: expenses,
                        date: date,
                      ),
                    );
                  }
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final date = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          DateFormat('d/M').format(date),
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(7, (index) {
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: revenueData[index],
                      color: Colors.pink,
                      width: 8,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                    ),
                    BarChartRodData(
                      toY: expenseData[index],
                      color: Colors.orange,
                      width: 8,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;

  const _SummaryCard({required this.title, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(amount, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
