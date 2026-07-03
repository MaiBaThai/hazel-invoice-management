import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/customer_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../data/models/app_settings_model.dart';
import '../../../data/models/invoice_model.dart';

class CustomerHistoryDialog extends StatefulWidget {
  final String customerId;
  final String customerName;
  final String customerPhone;

  const CustomerHistoryDialog({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
  });

  @override
  State<CustomerHistoryDialog> createState() => _CustomerHistoryDialogState();
}

class _CustomerHistoryDialogState extends State<CustomerHistoryDialog> {
  late String _currentName;
  late String _currentPhone;

  @override
  void initState() {
    super.initState();
    _currentName = widget.customerName;
    _currentPhone = widget.customerPhone;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CustomerProvider>(context, listen: false)
          .loadCustomerDetails(widget.customerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CustomerProvider>(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(_currentPhone, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditCustomerDialog(context);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit Info')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete Customer', style: TextStyle(color: Colors.red))),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            if (provider.isLoadingDetails)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (provider.customerInvoices.isEmpty)
              const Expanded(child: Center(child: Text('No past invoices found.')))
            else
              Expanded(
                child: ListView.separated(
                  itemCount: provider.customerInvoices.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final invoice = provider.customerInvoices[index];
                    return _InvoiceTile(invoice: invoice);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditCustomerDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: _currentName);
    final phoneCtrl = TextEditingController(text: _currentPhone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone (Optional)'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              
              await Provider.of<CustomerProvider>(context, listen: false)
                  .updateCustomer(widget.customerId, nameCtrl.text.trim(), phoneCtrl.text.trim());
                  
              if (!mounted) return;
              setState(() {
                _currentName = nameCtrl.text.trim();
                _currentPhone = phoneCtrl.text.trim();
              });
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Customer?', style: TextStyle(color: Colors.red)),
        content: const Text('Are you sure you want to delete this customer? All associated invoices will also be permanently deleted. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final dialogNavigator = Navigator.of(dialogContext);

              await Provider.of<CustomerProvider>(context, listen: false)
                  .deleteCustomer(widget.customerId);
              
              if (dialogContext.mounted) {
                dialogNavigator.pop(); // Close confirmation dialog
              }
              if (context.mounted) {
                navigator.pop(); // Close history dialog
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final Invoice invoice;

  const _InvoiceTile({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.decimalPattern();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    final settingsProvider = Provider.of<SettingsProvider>(context);
    final businessConfig = settingsProvider.settings?.businessConfig ?? BusinessConfig(businessName: 'My Salon', currencySymbol: '\$');

    String formatCurrency(num amount) {
      final formatted = format.format(amount);
      return businessConfig.isPrefix ? '${businessConfig.currencySymbol}$formatted' : '$formatted${businessConfig.currencySymbol}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (invoice.sessionStart != null && invoice.sessionEnd != null) ...[
                Text(
                  '${DateFormat('dd/MM/yyyy').format(invoice.sessionStart!)} (${DateFormat('HH:mm').format(invoice.sessionStart!)} - ${DateFormat('HH:mm').format(invoice.sessionEnd!)})',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ] else ...[
                Text(
                  dateFormat.format(invoice.createdAt),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
              Text(
                formatCurrency(invoice.finalTotal),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pink, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...invoice.services.map<Widget>((s) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('- ${s.serviceName}', style: const TextStyle(fontSize: 14)),
                  Text(formatCurrency(s.price), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              )),
          if (invoice.discountPercent > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Discount', style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                  Text('${format.format(invoice.discountPercent)}%', style: const TextStyle(fontSize: 14, color: Colors.green)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
