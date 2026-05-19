import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/expense_provider.dart';
import 'widgets/expense_summary_dialog.dart';
import 'package:intl/intl.dart';
import '../../core/providers/settings_provider.dart';
import '../../data/models/app_settings_model.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final List<TextEditingController> _descControllers = [];
  final List<TextEditingController> _costControllers = [];
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    for (var c in _descControllers) c.dispose();
    for (var c in _costControllers) c.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _syncWithProvider(ExpenseProvider provider) {
    while (_descControllers.length < provider.items.length) {
      final index = _descControllers.length;
      final item = provider.items[index];
      _descControllers.add(TextEditingController(text: item.description));
      final costText = item.cost == 0 ? '' : (item.cost == item.cost.toInt() ? item.cost.toInt().toString() : item.cost.toString());
      _costControllers.add(TextEditingController(text: costText));
    }
    while (_descControllers.length > provider.items.length) {
      _descControllers.last.dispose();
      _descControllers.removeLast();
      _costControllers.last.dispose();
      _costControllers.removeLast();
    }
  }

  final List<Map<String, String>> _categories = [
    {'label': 'Rent', 'icon': 'home', 'sub': 'Tiền nhà'},
    {'label': 'Supplies', 'icon': 'inventory_2', 'sub': 'Đồ dùng'},
    {'label': 'Utilities', 'icon': 'bolt', 'sub': 'Điện, Nước, Net'},
  ];

  IconData _getIcon(String name) {
    switch (name) {
      case 'home': return Icons.home_work_outlined;
      case 'inventory_2': return Icons.inventory_2_outlined;
      case 'bolt': return Icons.bolt_outlined;
      default: return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    _syncWithProvider(provider);

    final settingsProvider = Provider.of<SettingsProvider>(context);
    final businessConfig = settingsProvider.settings?.businessConfig ?? BusinessConfig(businessName: 'Hazel Nails', currencySymbol: 'k');
    
    String formatCurrency(num amount) {
      final formatted = NumberFormat.decimalPattern().format(amount);
      return businessConfig.isPrefix ? '${businessConfig.currencySymbol}$formatted' : '$formatted${businessConfig.currencySymbol}';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              provider.reset();
              _noteController.clear();
              setState(() {});
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _categories.map((cat) {
                return InkWell(
                  onTap: () {
                    provider.addItem(description: cat['label']!);
                    setState(() {});
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 56) / 3,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.2)),
                    ),
                    child: Column(
                      children: [
                        Icon(_getIcon(cat['icon']!), color: Colors.orange),
                        const SizedBox(height: 4),
                        Text(cat['label']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        Text(cat['sub']!, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Transaction Items', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () {
                    provider.addItem();
                    setState(() {});
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Custom'),
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _descControllers[index],
                        decoration: InputDecoration(
                          hintText: 'Item description',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (val) => provider.updateItem(index, val, provider.items[index].cost),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _costControllers[index],
                        decoration: InputDecoration(
                          hintText: 'Cost',
                          prefixText: businessConfig.isPrefix ? businessConfig.currencySymbol : null,
                          suffixText: !businessConfig.isPrefix ? businessConfig.currencySymbol : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (val) => provider.updateItem(index, provider.items[index].description, double.tryParse(val) ?? 0),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () {
                        provider.removeItem(index);
                        setState(() {});
                      },
                    ),
                  ],
                );
              },
            ),
            if (provider.items.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No items added yet', style: TextStyle(color: Colors.grey[400])),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const Text('Note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Add a note (optional)...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (val) => provider.setNote(val),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(
                        formatCurrency(provider.totalCost),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: provider.items.isEmpty ? null : () => showDialog(
                        context: context,
                        builder: (context) => const ExpenseSummaryDialog(),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('REVIEW TRANSACTION', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
