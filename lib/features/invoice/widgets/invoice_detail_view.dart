import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/invoice_model.dart';

class InvoiceDetailView extends StatelessWidget {
  final Invoice invoice;
  final ScrollController? scrollController;

  const InvoiceDetailView({
    super.key,
    required this.invoice,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.decimalPattern();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Column(
      children: [
        // Drag Handle
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        // Close Button & Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 8, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Invoice Detail', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(invoice.customerName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(dateFormat.format(invoice.createdAt), style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text(
                    '${format.format(invoice.finalTotal)}k',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pink, fontSize: 28),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text('SERVICES', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
              const Divider(),
              const SizedBox(height: 8),
              ...invoice.services.map<Widget>((s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(s.serviceName, style: const TextStyle(fontSize: 17))),
                        Text('${format.format(s.price)}k', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )),
              if (invoice.discountPercent > 0) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Discount', style: TextStyle(fontSize: 17, fontStyle: FontStyle.italic, color: Colors.green)),
                    Text('-${invoice.discountPercent}%', style: const TextStyle(fontSize: 17, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              if (invoice.photoUrls.isNotEmpty) ...[
                const Text('PHOTOS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                const Divider(),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: invoice.photoUrls.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          invoice.photoUrls[index],
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
