import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/customer_provider.dart';
import '../../core/providers/subscription_provider.dart';
import '../subscription/paywall_bottom_sheet.dart';
import '../../core/providers/invoice_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../data/models/customer_note_model.dart';
import '../../data/models/invoice_model.dart';
import '../../data/models/app_settings_model.dart';
import '../invoice/widgets/invoice_summary_dialog.dart';

import 'package:image_picker/image_picker.dart';
import '../../core/utils/ui_helper.dart';

class CustomerDetailPage extends StatefulWidget {
  final String customerId;

  const CustomerDetailPage({super.key, required this.customerId});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomerDetails(widget.customerId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subProvider = context.watch<SubscriptionProvider>();
    final isPremium = subProvider.isPremium;

    return Consumer<CustomerProvider>(
      builder: (context, provider, child) {
        final customer = provider.selectedCustomer;

        if (provider.isLoadingDetails || customer == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(customer.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _showEditDialog(context, provider),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmDelete(context, provider),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: [
                const Tab(text: 'Invoices', icon: Icon(Icons.history)),
                Tab(
                  text: 'Photos', 
                  icon: isPremium 
                      ? const Icon(Icons.photo_library) 
                      : const Icon(Icons.lock_outline, color: Colors.grey),
                ),
                const Tab(text: 'Notes', icon: Icon(Icons.note_alt_outlined)),
              ],
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildInvoicesTab(context, provider),
              _buildPhotosTab(context, provider, isPremium),
              _buildNotesTab(context, provider),
            ],
          ),
          floatingActionButton: _tabController.index == 2
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddEditNoteDialog(context, provider),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Note'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                )
              : null,
        );
      },
    );
  }

  Widget _buildInvoicesTab(BuildContext context, CustomerProvider provider) {
    if (provider.customerInvoices.isEmpty) {
      return const Center(child: Text('No invoices found'));
    }

    final settingsProvider = Provider.of<SettingsProvider>(context);
    final businessConfig = settingsProvider.settings?.businessConfig ?? BusinessConfig(businessName: 'My Salon', currencySymbol: '\$');
    
    String formatCurrency(num amount) {
      final formatted = NumberFormat.decimalPattern().format(amount);
      return businessConfig.isPrefix ? '${businessConfig.currencySymbol}$formatted' : '$formatted${businessConfig.currencySymbol}';
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.customerInvoices.length,
      itemBuilder: (context, index) {
        final invoice = provider.customerInvoices[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(
              DateFormat('dd/MM/yyyy').format(invoice.sessionStart ?? invoice.createdAt),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                invoice.sessionStart != null && invoice.sessionEnd != null
                    ? '${DateFormat('HH:mm').format(invoice.sessionStart!)} - ${DateFormat('HH:mm').format(invoice.sessionEnd!)}'
                    : DateFormat('HH:mm').format(invoice.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrency(invoice.finalTotal),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.primary),
                ),
                if (invoice.staffNames.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 100),
                      child: Text(
                        invoice.staffNames.join(', '),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...invoice.services.map((s) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(s.serviceName),
                            Text(formatCurrency(s.price)),
                          ],
                        )),
                    const Divider(),
                    if (invoice.staffNames.isNotEmpty ||
                        invoice.commissionPercent > 0 ||
                        invoice.tip > 0 ||
                        invoice.notes.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (invoice.staffNames.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Text('Staff: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Expanded(child: Text(invoice.staffNames.join(', '), style: const TextStyle(fontSize: 13))),
                                ],
                              ),
                            ],
                            if (invoice.commissionPercent > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Text('Commission: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(
                                    '${invoice.commissionPercent}% (${formatCurrency((invoice.subtotal * (1 - invoice.discountPercent / 100)) * (invoice.commissionPercent / 100))})',
                                    style: const TextStyle(fontSize: 13, color: Colors.teal),
                                  ),
                                ],
                              ),
                            ],
                            if (invoice.tip > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Text('Tip: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(
                                    formatCurrency(invoice.tip),
                                    style: TextStyle(fontSize: 13, color: Colors.amber[900], fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                            if (invoice.notes.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Notes: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Expanded(child: Text(invoice.notes, style: const TextStyle(fontSize: 13))),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (invoice.photoUrls.isNotEmpty) ...[
                      const Text('Photos:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: invoice.photoUrls.map((url) => Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: GestureDetector(
                                  onTap: () => _viewImage(context, url),
                                  child: Image.network(
                                    url,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: -10,
                                right: -10,
                                child: IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                                  onPressed: () => _confirmDeletePhoto(context, provider, invoice.id, widget.customerId, url),
                                ),
                              ),
                            ],
                          )).toList(),
                        ),
                      ),
                    ],
                    if (provider.isUploadingPhoto)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              final invoiceProvider = context.read<InvoiceProvider>();
                              final customer = provider.selectedCustomer!;
                              invoiceProvider.loadInvoiceForEditing(invoice, customer);
                              showDialog(
                                context: context,
                                builder: (_) => const InvoiceSummaryDialog(),
                              );
                            },
                            icon: const Icon(Icons.receipt_long),
                            label: const Text('View Receipt'),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final source = await showImageSourceSheet(context);
                              if (source != null && context.mounted) {
                                provider.uploadPhotoForInvoice(invoice.id, widget.customerId, source);
                              }
                            },
                            icon: const Icon(Icons.add_a_photo),
                            label: const Text('Add Photo'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhotosTab(BuildContext context, CustomerProvider provider, bool isPremium) {
    if (!isPremium) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock_outline, size: 48, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 24),
              const Text(
                'Photo Journaling is Premium',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Keep a visual history of your client\'s work! Upgrade to Premium to upload and attach photos directly to customer invoices.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => PaywallBottomSheet.show(
                  context,
                  titleExplanation: "Upgrade to Premium to upload work photos and start building your client photo portfolios!",
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('GO PREMIUM'),
              ),
            ],
          ),
        ),
      );
    }

    final List<Map<String, String>> allPhotos = [];
    for (var inv in provider.customerInvoices) {
      for (var url in inv.photoUrls) {
        if (url.isNotEmpty) {
          allPhotos.add({'url': url, 'invoiceId': inv.id});
        }
      }
        }

    if (allPhotos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No photos yet', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: allPhotos.length,
      itemBuilder: (context, index) {
        final photoData = allPhotos[index];
        final url = photoData['url']!;
        final invoiceId = photoData['invoiceId']!;

        return Stack(
          children: [
            GestureDetector(
              onTap: () => _viewImage(context, url),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(url),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -8,
              right: -8,
              child: IconButton(
                icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                onPressed: () => _confirmDeletePhoto(context, provider, invoiceId, widget.customerId, url),
              ),
            ),
          ],
        );
      },
    );
  }

  void _viewImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(child: Image.network(url)),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CustomerProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer?'),
        content: const Text('This will delete the customer, all invoices, and all photos. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await provider.deleteCustomer(widget.customerId);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to customer list
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePhoto(BuildContext context, CustomerProvider provider, String invoiceId, String customerId, String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: const Text('Are you sure you want to delete this photo? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirm dialog
              try {
                await provider.deletePhoto(invoiceId, customerId, url);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Photo deleted successfully')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting photo: $e')),
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

  void _showEditDialog(BuildContext context, CustomerProvider provider) {
    final customer = provider.selectedCustomer!;
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await provider.updateCustomer(
                  widget.customerId,
                  nameController.text.trim(),
                  phoneController.text.trim(),
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab(BuildContext context, CustomerProvider provider) {
    final customerNotes = provider.customerNotes;
    final invoiceNotes = provider.customerInvoices
        .where((inv) => inv.notes.trim().isNotEmpty)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Direct Customer Notes Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Customer Notes',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            if (customerNotes.isNotEmpty)
              Text(
                '${customerNotes.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (customerNotes.isEmpty)
          InkWell(
            onTap: () => _showAddEditNoteDialog(context, provider),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_note, color: Colors.grey[400], size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Enter notes for customer (e.g. skin sensitivity, preferences...)',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          ...customerNotes.map((note) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                elevation: 0,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.sticky_note_2_outlined, size: 16, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(note.createdAt),
                                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                              ),
                              if (note.updatedAt != null)
                                Text(
                                  ' (edited)',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[400], fontStyle: FontStyle.italic),
                                ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Edit Note',
                                onPressed: () => _showAddEditNoteDialog(context, provider, existingNote: note),
                              ),
                              const SizedBox(width: 12),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Delete Note',
                                onPressed: () => _confirmDeleteNote(context, provider, note.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        note.content,
                        style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 16),
        ],

        // Invoice Linked Notes Section
        if (invoiceNotes.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Notes from Invoices',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                '${invoiceNotes.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...invoiceNotes.map((inv) {
            final dateStr = inv.sessionStart != null
                ? DateFormat('dd/MM/yyyy').format(inv.sessionStart!)
                : DateFormat('dd/MM/yyyy').format(inv.createdAt);
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              elevation: 0,
              color: Colors.grey[50],
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blue.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.receipt_outlined, size: 13, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                '[Invoice - $dateStr]',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            final invoiceProvider = context.read<InvoiceProvider>();
                            final customer = provider.selectedCustomer!;
                            invoiceProvider.loadInvoiceForEditing(inv, customer);
                            showDialog(
                              context: context,
                              builder: (_) => const InvoiceSummaryDialog(),
                            );
                          },
                          icon: const Icon(Icons.visibility_outlined, size: 14),
                          label: const Text('View', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      inv.notes,
                      style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
                    ),
                    if (inv.staffNames.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Staff: ${inv.staffNames.join(', ')}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  void _showAddEditNoteDialog(BuildContext context, CustomerProvider provider, {CustomerNote? existingNote}) {
    final controller = TextEditingController(text: existingNote?.content ?? '');
    final isEditing = existingNote != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Customer Note' : 'Add Customer Note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Enter notes for customer (e.g. skin sensitivity, preferences)...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(context);
              if (isEditing) {
                await provider.updateCustomerNote(widget.customerId, existingNote.id, text);
              } else {
                await provider.addCustomerNote(widget.customerId, text);
              }
            },
            child: Text(isEditing ? 'UPDATE' : 'ADD NOTE'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteNote(BuildContext context, CustomerProvider provider, String noteId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note?'),
        content: const Text('Are you sure you want to delete this note? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteCustomerNote(widget.customerId, noteId);
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}
