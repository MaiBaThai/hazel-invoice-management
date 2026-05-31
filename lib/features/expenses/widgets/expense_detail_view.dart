import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/expense_provider.dart';
import '../../../core/providers/dashboard_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../data/models/app_settings_model.dart';
import '../../../data/models/expense_model.dart';
import '../../../main.dart';

class ExpenseDetailView extends StatelessWidget {
  final Expense expense;
  final ScrollController? scrollController;

  const ExpenseDetailView({
    super.key,
    required this.expense,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.decimalPattern();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final settingsProvider = Provider.of<SettingsProvider>(context);
    final businessConfig = settingsProvider.settings?.businessConfig ?? BusinessConfig(businessName: 'Hazel Nails', currencySymbol: 'k');

    String formatCurrency(num amount) {
      final formatted = format.format(amount);
      return businessConfig.isPrefix ? '${businessConfig.currencySymbol}$formatted' : '$formatted${businessConfig.currencySymbol}';
    }

    return Column(
      children: [
        // Drag Handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // Close Button & Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 8, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Expense Detail', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Transaction Record', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(dateFormat.format(expense.createdAt), style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text(
                    formatCurrency(expense.totalCost),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 28),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text('ITEMS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
              const Divider(),
              const SizedBox(height: 8),
              ...expense.items.map<Widget>((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(item.description.isEmpty ? 'Untitled Item' : item.description, style: const TextStyle(fontSize: 17))),
                        Text(formatCurrency(item.cost), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )),
              if (expense.note.isNotEmpty) ...[
                const SizedBox(height: 32),
                const Text('NOTE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                const Divider(),
                const SizedBox(height: 8),
                Text(expense.note, style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic)),
              ],
              const SizedBox(height: 48),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('DELETE', style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final expenseProvider = context.read<ExpenseProvider>();
                        expenseProvider.loadExpenseForEditing(expense);
                        
                        // Close both the bottom sheet and the daily details dialog
                        Navigator.pop(context); // Close detail view sheet
                        Navigator.pop(context); // Close daily details dialog
                        
                        // Switch tab to Expenses page
                        mainNavKey.currentState?.switchTab(1);
                      },
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('EDIT EXPENSE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text('Are you sure you want to delete this expense record? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx); // Close confirm dialog
              try {
                // Delete using the provider
                await context.read<ExpenseProvider>().deleteExpense(expense.id);
                
                // Refresh dashboard immediately
                if (context.mounted) {
                  Provider.of<DashboardProvider>(context, listen: false).loadDashboardData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Expense deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context); // Close detail view bottom sheet
                  Navigator.pop(context); // Close daily details dialog to reflect changes on dashboard page
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting expense: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
