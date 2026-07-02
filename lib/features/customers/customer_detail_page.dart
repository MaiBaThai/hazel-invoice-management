import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/customer_provider.dart';
import '../../core/providers/invoice_provider.dart';
import '../../core/providers/settings_provider.dart';
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
    _tabController = TabController(length: 2, vsync: this);
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
              tabs: const [
                Tab(text: 'Invoices', icon: Icon(Icons.history)),
                Tab(text: 'Photos', icon: Icon(Icons.photo_library)),
              ],
              indicatorColor: Colors.pink,
              labelColor: Colors.pink,
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildInvoicesTab(context, provider),
              _buildPhotosTab(provider),
            ],
          ),
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
              invoice.sessionStart != null && invoice.sessionEnd != null
                  ? '${DateFormat('dd/MM/yyyy').format(invoice.sessionStart!)} (${DateFormat('HH:mm').format(invoice.sessionStart!)} - ${DateFormat('HH:mm').format(invoice.sessionEnd!)})'
                  : DateFormat('dd/MM/yyyy HH:mm').format(invoice.createdAt),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              formatCurrency(invoice.finalTotal),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
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

  Widget _buildPhotosTab(CustomerProvider provider) {
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
}
