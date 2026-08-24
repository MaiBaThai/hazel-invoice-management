import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/providers/booking_provider.dart';
import '../../core/providers/customer_provider.dart';
import '../../data/models/booking_model.dart';
import '../../data/models/customer_model.dart';
import '../invoice/widgets/session_time_picker_dialog.dart';

class BookingDialog extends StatefulWidget {
  final Booking? booking;
  final DateTime? initialDate;

  const BookingDialog({super.key, this.booking, this.initialDate});

  @override
  State<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  Customer? _selectedCustomer;
  DateTime? _startTime;
  DateTime? _endTime;
  bool _isTitleAutoFilled = false;

  @override
  void initState() {
    super.initState();
    if (widget.booking != null) {
      final b = widget.booking!;
      _titleController.text = b.title;
      _notesController.text = b.notes;
      _startTime = b.startTime;
      _endTime = b.endTime;

      if (b.customerId != null) {
        // Find customer in cache
        final customers =
            Provider.of<CustomerProvider>(context, listen: false).allCustomers;
        final match = customers.where((c) => c.id == b.customerId).toList();
        if (match.isNotEmpty) {
          _selectedCustomer = match.first;
        } else {
          _selectedCustomer = Customer(
            id: b.customerId!,
            name: b.customerName ?? 'Unknown Client',
            phone: b.customerPhone ?? '',
          );
        }
      }
      _isTitleAutoFilled = true; // prevent overwriting title when editing
    } else {
      final baseDate = widget.initialDate ?? DateTime.now();
      _startTime = DateTime(baseDate.year, baseDate.month, baseDate.day, 9, 0);
      _endTime = DateTime(baseDate.year, baseDate.month, baseDate.day, 10, 0);
    }
  }

  void _selectCustomer(Customer customer) {
    setState(() {
      _selectedCustomer = customer;
      if (!_isTitleAutoFilled || _titleController.text.isEmpty) {
        _titleController.text = 'Booking - ${customer.name}';
        _isTitleAutoFilled = true;
      }
    });
  }

  void _clearCustomer() {
    setState(() {
      _selectedCustomer = null;
      _titleController.text = '';
      _isTitleAutoFilled = false;
    });
  }

  void _showCustomerSearch() {
    showDialog(
      context: context,
      builder: (context) => BookingCustomerSearchDialog(
        onSelect: _selectCustomer,
      ),
    );
  }

  Future<void> _saveBooking() async {
    if (!_formKey.currentState!.validate() ||
        _startTime == null ||
        _endTime == null) {
      return;
    }

    final bookingProvider =
        Provider.of<BookingProvider>(context, listen: false);

    // Conflict Check
    final conflicts = bookingProvider.getConflicts(
      _startTime!,
      _endTime!,
      excludeId: widget.booking?.id,
    );

    if (conflicts.isNotEmpty) {
      final conflictTitle = conflicts.first.title;
      final conflictStart = DateFormat('HH:mm').format(conflicts.first.startTime);
      final conflictEnd = DateFormat('HH:mm').format(conflicts.first.endTime);

      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Scheduling Conflict'),
          content: Text(
            'This slot overlaps with another booking for "$conflictTitle" ($conflictStart - $conflictEnd). Do you still want to save?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('SAVE ANYWAY'),
            ),
          ],
        ),
      );

      if (proceed != true) return;
    }

    final finalBooking = Booking(
      id: widget.booking?.id ?? '',
      customerId: _selectedCustomer?.id,
      customerName: _selectedCustomer?.name,
      customerPhone: _selectedCustomer?.phone,
      title: _titleController.text.trim(),
      startTime: _startTime!,
      endTime: _endTime!,
      notes: _notesController.text.trim(),
      googleEventId: widget.booking?.googleEventId,
      appleEventId: widget.booking?.appleEventId,
      createdAt: widget.booking?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (widget.booking == null) {
        await bookingProvider.createBooking(finalBooking);
      } else {
        await bookingProvider.updateBooking(finalBooking);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving booking: $e')),
        );
      }
    }
  }

  Future<void> _deleteBooking() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Booking'),
        content: const Text('Are you sure you want to delete this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (proceed == true && widget.booking != null) {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      try {
        await bookingProvider.deleteBooking(widget.booking!);
        if (mounted) {
          Navigator.pop(context); // Close BookingDialog
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting booking: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.booking != null;
    final formattedTime = _startTime != null && _endTime != null
        ? '${DateFormat('dd/MM/yyyy  |  HH:mm').format(_startTime!)} - ${DateFormat('HH:mm').format(_endTime!)}'
        : 'Select Time Slot';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(isEditing ? 'Edit Booking' : 'Create Booking'),
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              onPressed: _deleteBooking,
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Customer selection
                const Text(
                  'CLIENT',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.1),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _selectedCustomer != null
                      ? ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(_selectedCustomer!.name),
                          subtitle: Text(_selectedCustomer!.phone),
                          trailing: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearCustomer,
                          ),
                        )
                      : TextButton.icon(
                          onPressed: _showCustomerSearch,
                          icon: Icon(Icons.person_add_alt_1,
                              color: Theme.of(context).colorScheme.primary),
                          label: Text(
                            'Select Client',
                            style: TextStyle(color: Theme.of(context).colorScheme.primary),
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Booking Title',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Time Slot
                const Text(
                  'TIME SLOT',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 1.1),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => SessionTimePickerDialog(
                        initialStart: _startTime,
                        initialEnd: _endTime,
                        onSave: (s, e) {
                          setState(() {
                            _startTime = s;
                            _endTime = e;
                          });
                        },
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[50],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            formattedTime,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _saveBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('SAVE'),
        ),
      ],
    );
  }
}

// Inline search customer dialog specifically for booking linking
class BookingCustomerSearchDialog extends StatefulWidget {
  final Function(Customer) onSelect;

  const BookingCustomerSearchDialog({super.key, required this.onSelect});

  @override
  State<BookingCustomerSearchDialog> createState() =>
      _BookingCustomerSearchDialogState();
}

class _BookingCustomerSearchDialogState
    extends State<BookingCustomerSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Customer> _results = [];

  @override
  void initState() {
    super.initState();
    final all =
        Provider.of<CustomerProvider>(context, listen: false).allCustomers;
    _results = List.from(all);
  }

  void _onSearchChanged(String query) {
    final all =
        Provider.of<CustomerProvider>(context, listen: false).allCustomers;
    if (query.trim().isEmpty) {
      setState(() {
        _results = List.from(all);
      });
      return;
    }
    final lower = query.toLowerCase();
    setState(() {
      _results = all.where((c) {
        return c.name.toLowerCase().contains(lower) ||
            c.phone.contains(query);
      }).toList();
    });
  }

  Future<void> _createNewClient() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final Customer? newCustomer = await showDialog<Customer>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Customer'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneCtrl,
                decoration:
                    const InputDecoration(labelText: 'Phone (Optional)'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final customerProvider =
                    Provider.of<CustomerProvider>(context, listen: false);
                try {
                  final newCust = await customerProvider.createNewCustomer(
                    nameCtrl.text.trim(),
                    phoneCtrl.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.pop(context, newCust);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding customer: $e')),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    if (newCustomer != null && mounted) {
      widget.onSelect(newCustomer);
      Navigator.pop(context); // Close Search Dialog
    }
  }

  @override
  Widget build(BuildContext context) {
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
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: _onSearchChanged,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: _results.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        heightFactor: 1.0,
                        child: Text('No customers found.'),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final customer = _results[index];
                        return ListTile(
                          title: Text(customer.name),
                          subtitle: Text(customer.phone),
                          onTap: () {
                            widget.onSelect(customer);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
            const Divider(),
            TextButton.icon(
              onPressed: _createNewClient,
              icon: Icon(Icons.person_add, color: Theme.of(context).colorScheme.primary),
              label: Text('Add New Customer',
                  style: TextStyle(color: Theme.of(context).colorScheme.primary)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CLOSE', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}
