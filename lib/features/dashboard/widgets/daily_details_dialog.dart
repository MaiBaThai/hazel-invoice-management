import 'package:flutter/material.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/expense_model.dart';
import '../../invoice/widgets/invoice_detail_view.dart';
import '../../expenses/widgets/expense_detail_view.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../data/models/app_settings_model.dart';

class DailyDetailsDialog extends StatelessWidget {
  final List<Invoice> invoices;
  final List<Expense> expenses;
  final DateTime date;

  const DailyDetailsDialog({
    super.key,
    required this.invoices,
    required this.expenses,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final businessConfig = settingsProvider.settings?.businessConfig ?? BusinessConfig(businessName: 'My Salon', currencySymbol: '\$');
    
    String formatCurrency(num amount) {
      final formatted = NumberFormat.decimalPattern().format(amount);
      return businessConfig.isPrefix ? '${businessConfig.currencySymbol}$formatted' : '$formatted${businessConfig.currencySymbol}';
    }

    final totalRevenue = invoices.fold(0.0, (sum, item) => sum + item.finalTotal);
    final totalExpenses = expenses.fold(0.0, (sum, item) => sum + item.totalCost);
    final netProfit = totalRevenue - totalExpenses;

    return DefaultTabController(
      length: 2,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Daily Performance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              TabBar(
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: [
                  Tab(text: 'Invoices (${invoices.length})'),
                  Tab(text: 'Expenses (${expenses.length})'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildInvoicesList(context, formatCurrency),
                    _buildExpensesList(context, formatCurrency),
                  ],
                ),
              ),
              const Divider(height: 1),
              _buildBottomSummary(formatCurrency, totalRevenue, totalExpenses, netProfit),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoicesList(BuildContext context, String Function(num) formatCurrency) {
    if (invoices.isEmpty) return const Center(child: Text('No invoices recorded', style: TextStyle(color: Colors.grey)));
    
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: invoices.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        return InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => DraggableScrollableSheet(
                initialChildSize: 0.9,
                maxChildSize: 0.9,
                minChildSize: 0.5,
                builder: (_, controller) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: InvoiceDetailView(
                    invoice: invoice,
                    scrollController: controller,
                  ),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(invoice.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        () {
                          final start = invoice.sessionStart;
                          final end = invoice.sessionEnd;
                          if (start != null && end != null) {
                            return '${DateFormat('dd/MM/yyyy HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}';
                          } else {
                            return DateFormat('dd/MM/yyyy HH:mm').format(invoice.createdAt);
                          }
                        }(),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(formatCurrency(invoice.finalTotal), style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpensesList(BuildContext context, String Function(num) formatCurrency) {
    if (expenses.isEmpty) return const Center(child: Text('No expenses recorded', style: TextStyle(color: Colors.grey)));

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: expenses.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => DraggableScrollableSheet(
                initialChildSize: 0.9,
                maxChildSize: 0.9,
                minChildSize: 0.5,
                builder: (_, controller) => Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: ExpenseDetailView(
                    expense: expense,
                    scrollController: controller,
                  ),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('dd/MM/yyyy HH:mm').format(expense.createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(formatCurrency(expense.totalCost), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  ],
                ),
                const SizedBox(height: 4),
                ...expense.items.map((item) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.subdirectory_arrow_right, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(item.description, style: const TextStyle(fontSize: 13))),
                      Text(formatCurrency(item.cost), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )),
                if (expense.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Text('Note: ${expense.note}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSummary(String Function(num) formatCurrency, double revenue, double expenses, double profit) {
    final isProfit = profit >= 0;
    final color = isProfit ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Revenue', style: TextStyle(fontSize: 13, color: Colors.grey)),
              Text(formatCurrency(revenue), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Expenses', style: TextStyle(fontSize: 13, color: Colors.grey)),
              Text('-${formatCurrency(expenses)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Net Profit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                '${isProfit ? "+" : ""}${formatCurrency(profit)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
