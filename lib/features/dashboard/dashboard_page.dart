import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../data/models/app_settings_model.dart';
import 'widgets/daily_details_dialog.dart';

enum DashboardChartView {
  performance,
  services,
  heatmap,
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DashboardChartView _activeChartView = DashboardChartView.performance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).loadDashboardData();
    });
  }

  Widget _buildChartViewSelector() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<DashboardChartView>(
        groupValue: _activeChartView,
        children: const {
          DashboardChartView.performance: Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('Performance', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          DashboardChartView.services: Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('Top Services', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          DashboardChartView.heatmap: Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text('Busiest Times', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        },
        onValueChanged: (value) {
          if (value != null) {
            setState(() {
              _activeChartView = value;
            });
          }
        },
      ),
    );
  }

  Widget _buildSelectedChartView(DashboardProvider provider, String Function(num) formatCurrency) {
    switch (_activeChartView) {
      case DashboardChartView.performance:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Performance Overview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text(
                  provider.selectedRange == DashboardRange.fourteenDays
                      ? 'Daily Revenue vs Expenses'
                      : provider.selectedRange == DashboardRange.ytd
                          ? 'Monthly Revenue vs Expenses'
                          : 'Weekly Revenue vs Expenses',
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildChart(provider, formatCurrency),
          ],
        );
      case DashboardChartView.services:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Top Services & Products', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text('By revenue & visits', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 8),
            _buildTopServices(provider, formatCurrency),
          ],
        );
      case DashboardChartView.heatmap:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Busiest Days & Times', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text('Volume by hour range', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 8),
            _buildHeatMap(provider),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final businessConfig = settingsProvider.settings?.businessConfig ?? BusinessConfig(businessName: 'My Salon', currencySymbol: '\$');
    
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Sliding Segment Selector
                    _buildRangeSelector(provider),
                    const SizedBox(height: 14),

                    // 2. Dynamic Summary Metrics Grid
                    _buildSummaryGrid(provider, formatCurrency),
                    const SizedBox(height: 20),

                    // 3. Chart View Selector
                    _buildChartViewSelector(),
                    const SizedBox(height: 16),

                    // 4. Selected Chart View
                    _buildSelectedChartView(provider, formatCurrency),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRangeSelector(DashboardProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<DashboardRange>(
        groupValue: provider.selectedRange,
        children: const {
          DashboardRange.fourteenDays: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('14 Days', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          DashboardRange.thirtyDays: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('30 Days', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          DashboardRange.ninetyDays: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('90 Days', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          DashboardRange.ytd: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('YTD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        },
        onValueChanged: (value) {
          if (value != null) {
            provider.selectedRange = value;
          }
        },
      ),
    );
  }

  Widget _buildSummaryGrid(DashboardProvider provider, String Function(num) formatCurrency) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.3,
      children: [
        _SummaryCard(
          title: 'REVENUE',
          amount: formatCurrency(provider.periodRevenue),
          color: Colors.pink,
          subtitle: '${provider.periodInvoiceCount} visit${provider.periodInvoiceCount == 1 ? "" : "s"}',
        ),
        _SummaryCard(
          title: 'EXPENSES',
          amount: formatCurrency(provider.periodExpenses),
          color: Colors.orange,
          subtitle: 'total cost',
        ),
        _SummaryCard(
          title: 'NET PROFIT',
          amount: '${provider.periodNetProfit >= 0 ? "+" : ""}${formatCurrency(provider.periodNetProfit)}',
          color: provider.periodNetProfit >= 0 ? Colors.green : Colors.red,
          subtitle: '${provider.periodProfitMargin.toStringAsFixed(0)}% margin',
        ),
        _SummaryCard(
          title: 'AVG TICKET',
          amount: formatCurrency(provider.periodAverageTicket),
          color: Colors.deepPurple,
          subtitle: 'per invoice',
        ),
      ],
    );
  }

  Widget _buildChart(DashboardProvider provider, String Function(num) formatCurrency) {
    final revenueData = provider.chartRevenueData;
    final expenseData = provider.chartExpenseData;
    final labels = provider.chartLabels;

    double maxY = 0;
    for (var d in revenueData) {
      if (d > maxY) maxY = d;
    }
    for (var d in expenseData) {
      if (d > maxY) maxY = d;
    }

    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100;

    final barWidth = provider.selectedRange == DashboardRange.fourteenDays ? 6.0 : 10.0;
    final showLabelsInterval = provider.selectedRange == DashboardRange.fourteenDays ? 2 : 1;

    return AspectRatio(
      aspectRatio: 1.5,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.grey.withOpacity(0.03),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
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
                      TextStyle(color: rod.color, fontWeight: FontWeight.bold, fontSize: 11),
                    );
                  },
                ),
                touchCallback: (FlTouchEvent event, barTouchResponse) {
                  if (event is FlTapUpEvent && barTouchResponse != null && barTouchResponse.spot != null) {
                    final index = barTouchResponse.spot!.touchedBarGroupIndex;
                    if (index >= 0 && index < revenueData.length) {
                      final details = provider.getDetailsForIndex(index);
                      showDialog(
                        context: context,
                        builder: (context) => DailyDetailsDialog(
                          invoices: details['invoices'],
                          expenses: details['expenses'],
                          date: details['date'],
                        ),
                      );
                    }
                  }
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < labels.length) {
                        // Skip some labels on 14 Days to prevent overlapping
                        if (provider.selectedRange == DashboardRange.fourteenDays && index % showLabelsInterval != 0) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Text(
                            labels[index],
                            style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.w500),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(revenueData.length, (index) {
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: revenueData[index],
                      color: Colors.pink,
                      width: barWidth,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3)),
                    ),
                    BarChartRodData(
                      toY: expenseData[index],
                      color: Colors.orange,
                      width: barWidth,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3)),
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

  Widget _buildTopServices(DashboardProvider provider, String Function(num) formatCurrency) {
    final services = provider.topServices;
    if (services.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('No service sales recorded in this period', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ),
      );
    }

    final first = services.isNotEmpty ? services[0] : null;
    final second = services.length > 1 ? services[1] : null;
    final third = services.length > 2 ? services[2] : null;
    final maxRevenue = first?.totalRevenue ?? 1.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _buildPodiumColumn(second, 2, maxRevenue, formatCurrency)),
          const SizedBox(width: 8),
          Expanded(child: _buildPodiumColumn(first, 1, maxRevenue, formatCurrency)),
          const SizedBox(width: 8),
          Expanded(child: _buildPodiumColumn(third, 3, maxRevenue, formatCurrency)),
        ],
      ),
    );
  }

  Widget _buildPodiumColumn(
    ServiceSummary? service,
    int rank,
    double maxRevenue,
    String Function(num) formatCurrency,
  ) {
    const double maxBarHeight = 80.0;
    final double barHeight = service != null && maxRevenue > 0
        ? (service.totalRevenue / maxRevenue) * maxBarHeight
        : 8.0;

    Color barColor;
    if (rank == 1) {
      barColor = Colors.pink;
    } else if (rank == 2) {
      barColor = Colors.pink.withOpacity(0.65);
    } else {
      barColor = Colors.pink.withOpacity(0.35);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (service != null) ...[
          Text(
            formatCurrency(service.totalRevenue),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            '${service.count} visit${service.count == 1 ? "" : "s"}',
            style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ] else ...[
          const Text('-', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          const Text('-', style: TextStyle(fontSize: 9, color: Colors.grey)),
        ],
        const SizedBox(height: 8),
        Container(
          height: barHeight,
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 45),
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
          child: service != null && barHeight > 24
              ? Center(
                  child: Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : const SizedBox(),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 32,
          child: Text(
            service?.name ?? 'Empty',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: service != null ? Colors.black87 : Colors.grey,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildHeatMap(DashboardProvider provider) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final timeSlots = ['9-11', '11-13', '13-15', '15-17', '17+'];
    
    int maxCount = 1;
    for (var row in provider.heatMapData) {
      for (var val in row) {
        if (val > maxCount) maxCount = val;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day headers (columns)
          Row(
            children: [
              const SizedBox(width: 45), // spacer for time slot labels
              ...days.map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ),
              )),
            ],
          ),
          const SizedBox(height: 8),
          // Time slot rows
          ...List.generate(5, (slotIndex) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: Row(
                children: [
                  // Time Slot Label
                  SizedBox(
                    width: 45,
                    child: Text(
                      timeSlots[slotIndex],
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                  // Cells (Mon-Sun)
                  ...List.generate(7, (dayIndex) {
                    final count = provider.heatMapData[dayIndex][slotIndex];
                    final opacity = count == 0 ? 0.03 : 0.1 + 0.9 * (count / maxCount);
                    final cellColor = count == 0 ? Colors.grey : Colors.pink;

                    return Expanded(
                      child: Tooltip(
                        message: '${days[dayIndex]} at ${timeSlots[slotIndex]}: $count visit${count == 1 ? "" : "s"}',
                        triggerMode: TooltipTriggerMode.tap,
                        child: Container(
                          height: 32,
                          margin: const EdgeInsets.symmetric(horizontal: 2.0),
                          decoration: BoxDecoration(
                            color: cellColor.withOpacity(opacity),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: count > 0 ? Colors.pink.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
                              width: 0.5,
                            ),
                          ),
                          child: count > 0 
                              ? Center(
                                  child: Text(
                                    '$count',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: opacity > 0.5 ? Colors.white : Colors.pink[800],
                                    ),
                                  ),
                                )
                              : const SizedBox(),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Fewer visits', style: TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(width: 4),
              ...List.generate(5, (i) {
                return Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.1 + 0.9 * (i / 4)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
              const SizedBox(width: 4),
              const Text('More visits', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  final String? subtitle;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 8.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: color.withOpacity(0.55),
                    fontSize: 8.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: TextStyle(
                color: color,
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
