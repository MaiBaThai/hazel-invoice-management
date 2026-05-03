import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/invoice_provider.dart';
import '../../core/providers/settings_provider.dart';
import 'widgets/customer_search_dialog.dart';
import 'widgets/add_customer_dialog.dart';
import 'widgets/invoice_summary_dialog.dart';
import 'package:intl/intl.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final List<TextEditingController> _nameControllers = [];
  final List<TextEditingController> _priceControllers = [];
  final TextEditingController _discountController = TextEditingController();

  @override
  void dispose() {
    for (var c in _nameControllers) {
      c.dispose();
    }
    for (var c in _priceControllers) {
      c.dispose();
    }
    _discountController.dispose();
    super.dispose();
  }

  void _syncWithProvider(InvoiceProvider provider) {
    // Ensure we have enough controllers
    while (_nameControllers.length < provider.services.length) {
      final index = _nameControllers.length;
      final service = provider.services[index];
      _nameControllers.add(TextEditingController(text: service.serviceName));
      final priceText = service.price == 0 ? '' : (service.price == service.price.toInt() ? service.price.toInt().toString() : service.price.toString());
      _priceControllers.add(TextEditingController(text: priceText));
    }
    // Remove extra controllers if needed
    while (_nameControllers.length > provider.services.length) {
      _nameControllers.last.dispose();
      _nameControllers.removeLast();
      _priceControllers.last.dispose();
      _priceControllers.removeLast();
    }
  }

  void _handleReset(InvoiceProvider provider) {
    provider.reset();
    setState(() {
      for (var c in _nameControllers) {
        c.dispose();
      }
      for (var c in _priceControllers) {
        c.dispose();
      }
      _nameControllers.clear();
      _priceControllers.clear();
      _discountController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InvoiceProvider>(context);
    
    // Check if provider was reset from elsewhere (like Summary Dialog)
    if (provider.selectedCustomer == null && provider.services.isEmpty && provider.discountPercent == 0) {
       if (_nameControllers.isNotEmpty || _discountController.text.isNotEmpty) {
          // Force clear local controllers if provider is empty
          for (var c in _nameControllers) c.dispose();
          for (var c in _priceControllers) c.dispose();
          _nameControllers.clear();
          _priceControllers.clear();
          _discountController.clear();
       }
    }

    _syncWithProvider(provider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text('Hazel Nails', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('v1.3.7', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _handleReset(provider),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Customer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _CustomerSelector(provider: provider),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () {
                    provider.addService();
                    setState(() {});
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Custom'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Quick Add Chips
            Consumer<SettingsProvider>(
              builder: (context, settingsProvider, child) {
                final predefinedServices = settingsProvider.settings?.predefinedServices ?? [];
                if (predefinedServices.isEmpty) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: predefinedServices.map((s) {
                      return ActionChip(
                        label: Text('${s.serviceName} (${s.price}k)'),
                        backgroundColor: Colors.pink.withOpacity(0.1),
                        side: BorderSide.none,
                        onPressed: () {
                          final emptyIndex = provider.services.indexWhere((item) => item.serviceName.isEmpty && item.price == 0);
                          if (emptyIndex != -1) {
                            provider.updateService(emptyIndex, s.serviceName, s.price);
                            _nameControllers[emptyIndex].text = s.serviceName;
                            // Format without .0 if it's a whole number
                            _priceControllers[emptyIndex].text = s.price == s.price.roundToDouble() ? s.price.toInt().toString() : s.price.toString();
                          } else {
                            provider.addService();
                            _syncWithProvider(provider);
                            final lastIndex = provider.services.length - 1;
                            provider.updateService(lastIndex, s.serviceName, s.price);
                            _nameControllers[lastIndex].text = s.serviceName;
                            _priceControllers[lastIndex].text = s.price == s.price.roundToDouble() ? s.price.toInt().toString() : s.price.toString();
                          }
                          setState((){});
                        },
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            // Service List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.services.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _nameControllers[index],
                        decoration: InputDecoration(
                          hintText: 'Service (e.g. Sơn Gel)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        onChanged: (val) => provider.updateService(index, val, provider.services[index].price),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _priceControllers[index],
                        decoration: InputDecoration(
                          hintText: 'Price',
                          suffixText: 'k',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (val) => provider.updateService(index, provider.services[index].serviceName, double.tryParse(val) ?? 0),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () {
                        provider.removeService(index);
                        setState(() {
                           _nameControllers[index].dispose();
                           _nameControllers.removeAt(index);
                           _priceControllers[index].dispose();
                           _priceControllers.removeAt(index);
                        });
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const Text('Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            // Summary UI
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal', style: TextStyle(color: Colors.grey)),
                      Text('${NumberFormat.decimalPattern().format(provider.subtotal)}k', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Discount (%)', style: TextStyle(color: Colors.grey)),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          controller: _discountController,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.pink),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.pink.withOpacity(0.3)),
                            ),
                            hintText: '0',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => provider.setDiscount(double.tryParse(val) ?? 0),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(
                        '${NumberFormat.decimalPattern().format(provider.finalTotal)}k',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.pink),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => showDialog(context: context, builder: (context) => const InvoiceSummaryDialog()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('REVIEW INVOICE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerSelector extends StatelessWidget {
  final InvoiceProvider provider;
  const _CustomerSelector({required this.provider});

  @override
  Widget build(BuildContext context) {
    final customer = provider.selectedCustomer;
    return Container(
      decoration: BoxDecoration(
        color: Colors.pink.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.pink.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () => showDialog(context: context, builder: (context) => const CustomerSearchDialog()),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.pink,
                child: Icon(customer == null ? Icons.person_outline : Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer?.name ?? 'No customer selected',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: customer == null ? Colors.grey : Colors.black,
                      ),
                    ),
                    if (customer != null)
                      Text(customer.phone, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              if (customer == null)
                TextButton(
                  onPressed: () => showDialog(context: context, builder: (context) => const AddCustomerDialog()),
                  child: const Text('ADD NEW'),
                ),
              if (customer != null)
                const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
