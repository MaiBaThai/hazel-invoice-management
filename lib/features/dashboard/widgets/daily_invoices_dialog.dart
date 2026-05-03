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
        constraints: const BoxConstraints(maxHeight: 700, maxWidth: 400),
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
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ListView.separated(
                    itemCount: invoices.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final invoice = invoices[index];
                      return ExpansionTile(
                        tilePadding: EdgeInsets.zero,
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
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...invoice.services.map((s) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(s.serviceName),
                                          Text('${format.format(s.price)}k'),
                                        ],
                                      ),
                                    )),
                                if (invoice.discountPercent > 0) ...[
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Discount (${invoice.discountPercent.toInt()}%)'),
                                      Text('-${format.format(invoice.subtotal * invoice.discountPercent / 100)}k'),
                                    ],
                                  ),
                                ],
                                if (invoice.photoUrls.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Text('Photos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    height: 60,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: invoice.photoUrls.length,
                                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                                      itemBuilder: (context, pIndex) {
                                        return GestureDetector(
                                          onTap: () => _viewImage(context, invoice.photoUrls[pIndex]),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: Image.network(
                                              invoice.photoUrls[pIndex],
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
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
}
