import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/staff_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../data/models/app_settings_model.dart';
import '../../data/models/staff_model.dart';
import '../../data/models/invoice_model.dart';

class StaffDetailPage extends StatefulWidget {
  final String staffId;

  const StaffDetailPage({super.key, required this.staffId});

  @override
  State<StaffDetailPage> createState() => _StaffDetailPageState();
}

class _StaffDetailPageState extends State<StaffDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().loadStaffDetails(widget.staffId);
    });
  }

  void _showEditDialog(BuildContext context, Staff staff) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: staff.name);
    final phoneController = TextEditingController(text: staff.phone);
    final commController = TextEditingController(
      text: staff.defaultCommissionPercent == 0
          ? ''
          : (staff.defaultCommissionPercent == staff.defaultCommissionPercent.toInt()
              ? staff.defaultCommissionPercent.toInt().toString()
              : staff.defaultCommissionPercent.toString()),
    );
    bool isActive = staff.isActive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Staff Member'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Full Name *'),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneController,
                    decoration: const InputDecoration(labelText: 'Phone (Optional)'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: commController,
                    decoration: const InputDecoration(
                      labelText: 'Default Commission (%)',
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Active Status'),
                    subtitle: Text(isActive ? 'Currently working' : 'Inactive / On leave'),
                    value: isActive,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setDialogState(() {
                        isActive = val;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final updated = staff.copyWith(
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                    defaultCommissionPercent: double.tryParse(commController.text) ?? 0.0,
                    isActive: isActive,
                  );
                  await context.read<StaffProvider>().updateStaff(updated);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Staff staff) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Staff'),
        content: Text('Are you sure you want to delete ${staff.name}? Previous invoices will still retain this staff name.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              await context.read<StaffProvider>().deleteStaff(staff.id);
              if (context.mounted) {
                Navigator.pop(context); // Go back to staff list
              }
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffProvider>(
      builder: (context, provider, child) {
        final staff = provider.selectedStaff;

        if (provider.isLoadingDetails || staff == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final settingsProvider = Provider.of<SettingsProvider>(context);
        final businessConfig = settingsProvider.settings?.businessConfig ??
            BusinessConfig(businessName: 'My Salon', currencySymbol: '\$');

        String formatCurrency(num amount) {
          final formatted = NumberFormat.decimalPattern().format(amount);
          return businessConfig.isPrefix
              ? '${businessConfig.currencySymbol}$formatted'
              : '$formatted${businessConfig.currencySymbol}';
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Staff',
                onPressed: () => _showEditDialog(context, staff),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete Staff',
                onPressed: () => _confirmDelete(context, staff),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => provider.loadStaffDetails(widget.staffId),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info & Earnings Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'S',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  staff.name,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  staff.phone.isNotEmpty ? staff.phone : 'No phone number',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: staff.isActive
                                            ? Colors.green.withOpacity(0.1)
                                            : Colors.grey.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        staff.isActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: staff.isActive ? Colors.green[800] : Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Default: ${staff.defaultCommissionPercent}%',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 28),
                      // 3 Earnings Metrics
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              context,
                              'Invoices',
                              provider.staffInvoices.length.toString(),
                              Colors.blue,
                            ),
                          ),
                          Container(width: 1, height: 40, color: Colors.grey[200]),
                          Expanded(
                            child: _buildMetricTile(
                              context,
                              'Commission',
                              formatCurrency(provider.staffTotalCommission),
                              Colors.orange,
                            ),
                          ),
                          Container(width: 1, height: 40, color: Colors.grey[200]),
                          Expanded(
                            child: _buildMetricTile(
                              context,
                              'Tips',
                              formatCurrency(provider.staffTotalTips),
                              Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Estimated Earnings',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            Text(
                              formatCurrency(provider.staffTotalEarnings),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Invoices Served',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (provider.staffInvoices.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'No invoices recorded for ${staff.name} yet.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                else
                  ...provider.staffInvoices.map((inv) => _buildInvoiceCard(context, inv, staff.name, formatCurrency)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricTile(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildInvoiceCard(
    BuildContext context,
    Invoice invoice,
    String staffName,
    String Function(num) formatCurrency,
  ) {
    final staffCount = invoice.staffNames.isEmpty ? 1 : invoice.staffNames.length;
    final commissionable = invoice.subtotal * (1 - invoice.discountPercent / 100);
    final totalComm = commissionable * (invoice.commissionPercent / 100);
    final myComm = totalComm / staffCount;
    final myTip = invoice.tip / staffCount;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ExpansionTile(
        title: Text(
          invoice.customerName.isNotEmpty ? invoice.customerName : 'Customer',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          DateFormat('dd/MM/yyyy HH:mm').format(invoice.createdAt),
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '+${formatCurrency(myComm + myTip)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 15,
              ),
            ),
            Text(
              'Total: ${formatCurrency(invoice.finalTotal)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Services:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                ...invoice.services.map((s) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(s.serviceName, style: const TextStyle(fontSize: 13)),
                          Text(formatCurrency(s.price), style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                    )),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Staff: ${invoice.staffNames.join(', ')}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (staffCount > 1)
                      Text('(Split between $staffCount)', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Commission (${invoice.commissionPercent}%):', style: const TextStyle(fontSize: 13)),
                    Text(formatCurrency(myComm), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
                if (invoice.tip > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tip Share:', style: TextStyle(fontSize: 13)),
                      Text(formatCurrency(myTip), style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.teal, fontSize: 13)),
                    ],
                  ),
                ],
                if (invoice.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('Note: ${invoice.notes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
