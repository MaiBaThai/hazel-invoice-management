import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/invoice_model.dart';

class DailyInvoicesDialog extends StatelessWidget {
  final List<Invoice> invoices;
  final DateTime date;

  const DailyInvoicesDialog({
    super.key,
    required this.invoices,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.decimalPattern();
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxHeight: 500, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Invoices',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      dateFormat.format(date),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 30),
            if (invoices.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text('No transactions for this day'),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: invoices.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        invoice.customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        DateFormat('HH:mm').format(invoice.createdAt),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Text(
                        '${format.format(invoice.finalTotal)}k',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.pink,
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Revenue',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${format.format(invoices.fold(0.0, (sum, item) => sum + item.finalTotal))}k',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                      fontSize: 18,
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
