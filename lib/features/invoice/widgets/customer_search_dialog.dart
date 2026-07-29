import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/invoice_provider.dart';
import 'add_customer_dialog.dart';

class CustomerSearchDialog extends StatefulWidget {
  const CustomerSearchDialog({super.key});

  @override
  State<CustomerSearchDialog> createState() => _CustomerSearchDialogState();
}

class _CustomerSearchDialogState extends State<CustomerSearchDialog> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Clear previous search results when opening the dialog
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<InvoiceProvider>(context, listen: false).clearSearchResults();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InvoiceProvider>(context);

    return AlertDialog(
      title: const Text('Select Customer'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => provider.searchCustomers(val),
            ),
            const SizedBox(height: 16),
            if (provider.isSearching)
              const CircularProgressIndicator()
            else if (provider.searchResults.isEmpty && _searchController.text.isNotEmpty)
              Column(
                children: [
                  const Text('No customers found.'),
                  TextButton(
                    onPressed: () => provider.showAllCustomers(),
                    child: const Text('Show all customers'),
                  ),
                ],
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: provider.searchResults.length,
                  itemBuilder: (context, index) {
                    final customer = provider.searchResults[index];
                    return ListTile(
                      title: Text(customer.name),
                      subtitle: Text(customer.phone),
                      onTap: () {
                        provider.selectCustomer(customer);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            const Divider(),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => const AddCustomerDialog(),
                );
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Add New Customer'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
      ],
    );
  }
}
