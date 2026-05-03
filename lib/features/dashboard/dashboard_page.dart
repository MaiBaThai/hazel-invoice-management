import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/providers/dashboard_provider.dart';
import 'widgets/daily_invoices_dialog.dart';

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
                    _buildSummaryCards(provider),
                    const SizedBox(height: 32),
                    const Text('Last 7 Days Revenue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _buildChart(provider),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCards(DashboardProvider provider) {
    final format = NumberFormat.decimalPattern();
    return Row(
      children: [
        Expanded(child: _SummaryCard(title: 'Today', amount: '${format.format(provider.todayRevenue)}k', color: Colors.pink)),
        const SizedBox(width: 8),
        Expanded(child: _SummaryCard(title: 'This Month', amount: '${format.format(provider.monthRevenue)}k', color: Colors.orange)),
        const SizedBox(width: 8),
        Expanded(child: _SummaryCard(title: 'This Year', amount: '${format.format(provider.yearRevenue)}k', color: Colors.blue)),
      ],
    );
  }

  Widget _buildChart(DashboardProvider provider) {
    final data = provider.last7DaysRevenue;
    double maxY = 0;
    for (var d in data) {
      if (d > maxY) maxY = d;
    }
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100;

    return AspectRatio(
      aspectRatio: 1.5,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.pink.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchCallback: (FlTouchEvent event, barTouchResponse) {
                  if (!event.isInterestedForInteractions ||
                      barTouchResponse == null ||
                      barTouchResponse.spot == null) {
                    return;
                  }
                  if (event is FlTapUpEvent) {
                    final index = barTouchResponse.spot!.touchedBarGroupIndex;
                    final invoices = provider.dailyInvoices[index];
                    final date = DateTime.now().subtract(Duration(days: 6 - index));
                    showDialog(
                      context: context,
                      builder: (context) => DailyInvoicesDialog(
                        invoices: invoices,
                        date: date,
                      ),
                    );
                  }
                },
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${NumberFormat.decimalPattern().format(rod.toY)}k',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    );
                  },
                ),
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
                      toY: data[index],
                      color: Colors.pink,
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: maxY,
                        color: Colors.pink.withOpacity(0.1),
                      ),
                    )
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
