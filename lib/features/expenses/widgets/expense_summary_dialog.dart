import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/expense_provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../data/models/app_settings_model.dart';

class ExpenseSummaryDialog extends StatelessWidget {
  const ExpenseSummaryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final businessConfig = settingsProvider.settings?.businessConfig ?? BusinessConfig(businessName: 'Hazel Nails', currencySymbol: 'k');
    
    String formatCurrency(num amount) {
      final formatted = NumberFormat.decimalPattern().format(amount);
      return businessConfig.isPrefix ? '${businessConfig.currencySymbol}$formatted' : '$formatted${businessConfig.currencySymbol}';
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Expense Summary',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.items.length,
                  itemBuilder: (context, index) {
                    final item = provider.items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(item.description.isEmpty ? 'Untitled Item' : item.description)),
                          Text(formatCurrency(item.cost), style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (provider.note.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Note:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(provider.note, style: const TextStyle(fontStyle: FontStyle.italic)),
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Cost', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(
                    formatCurrency(provider.totalCost),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: provider.isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('EDIT'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: provider.isSaving ? null : () async {
                        try {
                          await provider.saveExpense();
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Expense saved successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error saving expense: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: provider.isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('SAVE RECORD'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
