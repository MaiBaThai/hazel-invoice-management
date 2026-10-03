import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/invoice_provider.dart';
import '../../core/providers/staff_provider.dart';
import '../../core/providers/subscription_provider.dart';
import '../../core/providers/settings_provider.dart';
import 'widgets/customer_search_dialog.dart';
import 'widgets/add_customer_dialog.dart';
import 'widgets/invoice_summary_dialog.dart';
import 'widgets/session_time_picker_dialog.dart';
import '../../data/models/app_settings_model.dart';
import '../settings/settings_page.dart';
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
  final TextEditingController _commissionController = TextEditingController();
  final TextEditingController _tipController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _showSessionTimeError = false;
  String? _syncedEditingInvoiceId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      if (!staffProvider.hasLoadedOnce) {
        staffProvider.loadStaff();
      }
    });
  }

  @override
  void dispose() {
    for (var c in _nameControllers) {
      c.dispose();
    }
    for (var c in _priceControllers) {
      c.dispose();
    }
    _discountController.dispose();
    _commissionController.dispose();
    _tipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _syncWithProvider(InvoiceProvider provider) {
    // Ensure we have enough controllers
    while (_nameControllers.length < provider.services.length) {
      final index = _nameControllers.length;
      final service = provider.services[index];
      _nameControllers.add(TextEditingController(text: service.serviceName));
      final priceText = service.price == 0
          ? ''
          : (service.price == service.price.toInt()
              ? service.price.toInt().toString()
              : service.price.toString());
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
      _showSessionTimeError = false;
      _syncedEditingInvoiceId = null;
      for (var c in _nameControllers) {
        c.dispose();
      }
      for (var c in _priceControllers) {
        c.dispose();
      }
      _nameControllers.clear();
      _priceControllers.clear();
      _discountController.clear();
      _commissionController.clear();
      _tipController.clear();
      _notesController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InvoiceProvider>(context);

    // If an invoice was loaded for editing, force sync all form fields to match the invoice
    if (provider.isEditing && provider.editingInvoiceId != _syncedEditingInvoiceId) {
      _syncedEditingInvoiceId = provider.editingInvoiceId;
      _discountController.text = provider.discountPercent > 0
          ? (provider.discountPercent == provider.discountPercent.toInt()
              ? provider.discountPercent.toInt().toString()
              : provider.discountPercent.toString())
          : '';
      _commissionController.text = provider.commissionPercent > 0
          ? (provider.commissionPercent == provider.commissionPercent.toInt()
              ? provider.commissionPercent.toInt().toString()
              : provider.commissionPercent.toString())
          : '';
      _tipController.text = provider.tip > 0
          ? (provider.tip == provider.tip.toInt()
              ? provider.tip.toInt().toString()
              : provider.tip.toString())
          : '';
      _notesController.text = provider.notes;
    } else if (!provider.isEditing && _syncedEditingInvoiceId != null) {
      _syncedEditingInvoiceId = null;
    }

    // Check if provider was reset from elsewhere (like Summary Dialog)
    if (provider.selectedCustomer == null &&
        provider.services.isEmpty &&
        provider.discountPercent == 0 &&
        provider.selectedStaffNames.isEmpty &&
        provider.tip == 0 &&
        provider.commissionPercent == 0 &&
        provider.notes.isEmpty) {
      if (_nameControllers.isNotEmpty ||
          _discountController.text.isNotEmpty ||
          _commissionController.text.isNotEmpty ||
          _tipController.text.isNotEmpty ||
          _notesController.text.isNotEmpty) {
        // Force clear local controllers if provider is empty
        for (var c in _nameControllers) {
          c.dispose();
        }
        for (var c in _priceControllers) {
          c.dispose();
        }
        _nameControllers.clear();
        _priceControllers.clear();
        _discountController.clear();
        _commissionController.clear();
        _tipController.clear();
        _notesController.clear();
        _syncedEditingInvoiceId = null;
      }
    }

    if (_discountController.text.isEmpty && provider.discountPercent > 0) {
      _discountController.text = provider.discountPercent == provider.discountPercent.toInt()
          ? provider.discountPercent.toInt().toString()
          : provider.discountPercent.toString();
    }
    if (_commissionController.text.isEmpty && provider.commissionPercent > 0) {
      _commissionController.text = provider.commissionPercent == provider.commissionPercent.toInt()
          ? provider.commissionPercent.toInt().toString()
          : provider.commissionPercent.toString();
    }
    if (_tipController.text.isEmpty && provider.tip > 0) {
      _tipController.text = provider.tip == provider.tip.toInt()
          ? provider.tip.toInt().toString()
          : provider.tip.toString();
    }
    if (_notesController.text.isEmpty && provider.notes.isNotEmpty) {
      _notesController.text = provider.notes;
    }

    _syncWithProvider(provider);

    final settingsProvider = Provider.of<SettingsProvider>(context);
    final subProvider = context.watch<SubscriptionProvider>();
    final businessConfig = settingsProvider.settings?.businessConfig ??
        BusinessConfig(businessName: 'My Salon', currencySymbol: '\$');

    String formatCurrency(num amount) {
      final formatted = NumberFormat.decimalPattern().format(amount);
      return businessConfig.isPrefix
          ? '${businessConfig.currencySymbol}$formatted'
          : '$formatted${businessConfig.currencySymbol}';
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              Text(businessConfig.businessName,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Text('v1.3.7',
                  style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Reset',
              onPressed: () => _handleReset(provider),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!subProvider.isPremium)
                FutureBuilder<int>(
                  future: provider.getInvoiceCountForCurrentMonth(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    final limit = subProvider.freeInvoiceLimit;
                    final percent = (count / limit).clamp(0.0, 1.0);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Monthly Invoices',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Text(
                                '$count / $limit free',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percent,
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              if (provider.isEditing)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_note, color: Colors.amber[900], size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Editing Invoice',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.amber[900]),
                            ),
                            Text(
                              'All fields loaded. Make changes and review below.',
                              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => _handleReset(provider),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Cancel Edit',
                            style: TextStyle(fontSize: 12, color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              const Text('Customer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _InvoiceInfoCard(
                provider: provider,
                showSessionTimeError: _showSessionTimeError,
                onSessionTimeTap: () {
                  setState(() {
                    _showSessionTimeError = false;
                  });
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Staff',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  if (provider.selectedStaffNames.isNotEmpty)
                    Text(
                      '${provider.selectedStaffNames.length} selected',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Consumer<StaffProvider>(
                builder: (context, staffProvider, child) {
                  final staffList = staffProvider.activeStaff;
                  if (staffList.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.people_outline,
                              size: 18, color: Colors.grey[400]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No staff found. Add staff in the Staff tab to select here.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[500]),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: staffList.map((staff) {
                      final isSelected =
                          provider.selectedStaffNames.contains(staff.name);
                      return FilterChip(
                        label: Text(staff.name),
                        selected: isSelected,
                        onSelected: (_) {
                          provider.toggleStaffName(staff.name,
                              defaultCommission: staff.defaultCommissionPercent);
                          if (provider.selectedStaffNames.isEmpty) {
                            provider.setCommissionPercent(0.0);
                            _commissionController.clear();
                          } else if (provider.selectedStaffNames.length == 1) {
                            final singleStaffName = provider.selectedStaffNames.first;
                            final singleStaff = staffList.where((s) => s.name == singleStaffName).firstOrNull;
                            final commission = singleStaff?.defaultCommissionPercent ?? 0.0;
                            provider.setCommissionPercent(commission);
                            if (commission == 0) {
                              _commissionController.clear();
                            } else {
                              _commissionController.text =
                                  commission == commission.toInt()
                                      ? commission.toInt().toString()
                                      : commission.toString();
                            }
                          } else {
                            if (provider.commissionPercent == 0) {
                              _commissionController.clear();
                            } else {
                              _commissionController.text =
                                  provider.commissionPercent ==
                                          provider.commissionPercent.toInt()
                                      ? provider.commissionPercent
                                          .toInt()
                                          .toString()
                                      : provider.commissionPercent.toString();
                            }
                          }
                        },
                        selectedColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.12),
                        checkmarkColor:
                            Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[800],
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[300]!,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Services',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  final predefinedServices =
                      settingsProvider.settings?.predefinedServices ?? [];
                  if (predefinedServices.isEmpty) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: predefinedServices.map((s) {
                        return ActionChip(
                          label: Text(
                              '${s.serviceName} (${formatCurrency(s.price)})'),
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                          side: BorderSide.none,
                          onPressed: () {
                            final emptyIndex = provider.services.indexWhere(
                                (item) =>
                                    item.serviceName.isEmpty &&
                                    item.price == 0);
                            if (emptyIndex != -1) {
                              provider.updateService(
                                  emptyIndex, s.serviceName, s.price);
                              _nameControllers[emptyIndex].text = s.serviceName;
                              // Format without .0 if it's a whole number
                              _priceControllers[emptyIndex].text =
                                  s.price == s.price.roundToDouble()
                                      ? s.price.toInt().toString()
                                      : s.price.toString();
                            } else {
                              provider.addService();
                              _syncWithProvider(provider);
                              final lastIndex = provider.services.length - 1;
                              provider.updateService(
                                  lastIndex, s.serviceName, s.price);
                              _nameControllers[lastIndex].text = s.serviceName;
                              _priceControllers[lastIndex].text =
                                  s.price == s.price.roundToDouble()
                                      ? s.price.toInt().toString()
                                      : s.price.toString();
                            }
                            setState(() {});
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
                      Text(
                        '${index + 1}.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _nameControllers[index],
                          decoration: InputDecoration(
                            hintText: 'Service (e.g. Sơn Gel)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          onChanged: (val) => provider.updateService(
                              index, val, provider.services[index].price),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _priceControllers[index],
                          decoration: InputDecoration(
                            hintText: 'Price',
                            prefixText: businessConfig.isPrefix
                                ? businessConfig.currencySymbol
                                : null,
                            suffixText: !businessConfig.isPrefix
                                ? businessConfig.currencySymbol
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => provider.updateService(
                              index,
                              provider.services[index].serviceName,
                              double.tryParse(val) ?? 0),
                        ),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
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
              const Text('Invoice Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              // Summary UI
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Subtotal',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14)),
                        Text(formatCurrency(provider.subtotal),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Discount (%)',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (provider.discountPercent > 0)
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  '-${formatCurrency(provider.subtotal * provider.discountPercent / 100)}',
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                              ),
                            SizedBox(
                              width: 70,
                              height: 36,
                              child: TextField(
                                controller: _discountController,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  isDense: true,
                                  filled: true,
                                  fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.03),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide:
                                        BorderSide(color: Theme.of(context).colorScheme.primary),
                                  ),
                                  hintText: '0',
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (val) => provider
                                    .setDiscount(double.tryParse(val) ?? 0),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Commission (%)',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 14)),
                            if (provider.commissionPercent > 0)
                              Text(
                                'Est: ${formatCurrency(provider.estimatedCommissionAmount)}',
                                style: TextStyle(
                                    color: Colors.teal[700],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500),
                              ),
                          ],
                        ),
                        SizedBox(
                          width: 70,
                          height: 36,
                          child: TextField(
                            controller: _commissionController,
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: Colors.teal.withOpacity(0.04),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: Colors.teal.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: Colors.teal.withOpacity(0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: Colors.teal),
                              ),
                              hintText: '0',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => provider
                                .setCommissionPercent(double.tryParse(val) ?? 0),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                                fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tip',
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 14)),
                            Text('(Paid directly to staff)',
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 11)),
                          ],
                        ),
                        SizedBox(
                          width: 90,
                          height: 36,
                          child: TextField(
                            controller: _tipController,
                            textAlign: TextAlign.right,
                            decoration: InputDecoration(
                              isDense: true,
                              filled: true,
                              fillColor: Colors.amber.withOpacity(0.05),
                              prefixText: businessConfig.isPrefix
                                  ? businessConfig.currencySymbol
                                  : null,
                              suffixText: !businessConfig.isPrefix
                                  ? businessConfig.currencySymbol
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: Colors.amber.withOpacity(0.4)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                    color: Colors.amber.withOpacity(0.4)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: Colors.amber),
                              ),
                              hintText: '0',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (val) =>
                                provider.setTip(double.tryParse(val) ?? 0),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.amber[900],
                                fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          formatCurrency(provider.finalTotal),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    ),
                    if (provider.tip > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('+ Staff Tip',
                              style: TextStyle(
                                  color: Colors.amber[900],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                          Text(
                            formatCurrency(provider.tip),
                            style: TextStyle(
                                color: Colors.amber[900],
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Invoice Notes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add notes about service, formulas, or preferences...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                onChanged: (val) => provider.setNotes(val),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (provider.selectedCustomer == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please select a customer')),
                      );
                      return;
                    }
                    if (provider.services.isEmpty || provider.subtotal <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Invoice must have at least one service')),
                      );
                      return;
                    }
                    if (!provider.isEditing &&
                        (provider.sessionStart == null ||
                            provider.sessionEnd == null)) {
                      setState(() {
                        _showSessionTimeError = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Please select session date & time')),
                      );
                      return;
                    }
                    showDialog(
                        context: context,
                        builder: (context) => const InvoiceSummaryDialog());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                      provider.isEditing ? 'REVIEW & UPDATE' : 'REVIEW INVOICE',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvoiceInfoCard extends StatelessWidget {
  final InvoiceProvider provider;
  final bool showSessionTimeError;
  final VoidCallback onSessionTimeTap;

  const _InvoiceInfoCard({
    required this.provider,
    required this.showSessionTimeError,
    required this.onSessionTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    final customer = provider.selectedCustomer;
    final start = provider.sessionStart;
    final end = provider.sessionEnd;
    final hasSession = start != null && end != null;

    final dateStr = hasSession ? DateFormat('dd/MM/yyyy').format(start) : '';
    final timeStr = hasSession
        ? '${DateFormat('HH:mm').format(start)} - ${DateFormat('HH:mm').format(end)}'
        : '';

    String durationText = '';
    if (hasSession) {
      final diffMinutes = end.difference(start).inMinutes;
      final hours = diffMinutes / 60.0;
      final formattedHours =
          hours.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
      durationText = '$formattedHours hr${hours == 1 ? '' : 's'}';
    }

    final Color sessionSubtitleColor;
    final String sessionSubtitleText;

    if (hasSession) {
      sessionSubtitleColor = Colors.black;
      sessionSubtitleText = '$dateStr | $timeStr ($durationText)';
    } else if (showSessionTimeError) {
      sessionSubtitleColor = Colors.amber[900]!;
      sessionSubtitleText = 'Mandatory field - tap to select';
    } else {
      sessionSubtitleColor = Colors.grey[500]!;
      sessionSubtitleText = 'Tap to select session time';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Customer Selector Row
          InkWell(
            onTap: () => showDialog(
                context: context,
                builder: (context) => const CustomerSearchDialog()),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(
                        customer == null ? Icons.person_outline : Icons.person),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Customer Details',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          customer?.name ?? 'Tap to select customer',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: customer == null
                                ? Colors.grey[500]
                                : Colors.black,
                          ),
                        ),
                        if (customer != null)
                          Text(customer.phone,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                  if (customer == null)
                    TextButton(
                      onPressed: () => showDialog(
                          context: context,
                          builder: (context) => const AddCustomerDialog()),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                      ),
                      child: const Text('ADD NEW',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  if (customer != null)
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: Colors.grey[100]),
          // Session Time Selector Row
          InkWell(
            onTap: () {
              onSessionTimeTap();
              showDialog(
                context: context,
                builder: (context) => SessionTimePickerDialog(
                  initialStart: provider.sessionStart,
                  initialEnd: provider.sessionEnd,
                  onSave: (s, e) => provider.setSessionRange(s, e),
                ),
              );
            },
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: showSessionTimeError && !hasSession
                        ? Colors.amber.withOpacity(0.1)
                        : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    foregroundColor: showSessionTimeError && !hasSession
                        ? Colors.amber
                        : Theme.of(context).colorScheme.primary,
                    child: Icon(hasSession
                        ? Icons.access_time_filled
                        : Icons.access_time),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Session Time',
                          style: TextStyle(
                            fontSize: 12,
                            color: showSessionTimeError && !hasSession
                                ? Colors.amber[900]
                                : Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          sessionSubtitleText,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: sessionSubtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: showSessionTimeError && !hasSession
                          ? Colors.amber[900]
                          : Colors.grey[400]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
