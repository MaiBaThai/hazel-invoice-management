import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../data/models/app_settings_model.dart';
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

    final settingsProvider = Provider.of<SettingsProvider>(context);
    final businessConfig = settingsProvider.settings?.businessConfig ?? BusinessConfig(businessName: 'Hazel Nails', currencySymbol: 'k');

    String formatCurrency(num amount) {
      final formatted = format.format(amount);
      return businessConfig.isPrefix ? '${businessConfig.currencySymbol}$formatted' : '$formatted${businessConfig.currencySymbol}';
    }

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
                        const SizedBox(height: 4),
                        if (invoice.sessionStart != null && invoice.sessionEnd != null) ...[
                          Text(
                            () {
                              final start = invoice.sessionStart!;
                              final end = invoice.sessionEnd!;
                              final diffMinutes = end.difference(start).inMinutes;
                              final hours = diffMinutes / 60.0;
                              final formattedHours = hours.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
                              final durationText = '($formattedHours hr${hours == 1 ? '' : 's'})';
                              final dateStr = DateFormat('dd/MM/yyyy').format(start);
                              final startStr = DateFormat('HH:mm').format(start);
                              final endStr = DateFormat('HH:mm').format(end);
                              return '$dateStr  $startStr - $endStr $durationText';
                            }(),
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ] else ...[
                          Text(dateFormat.format(invoice.createdAt), style: const TextStyle(color: Colors.grey)),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    formatCurrency(invoice.finalTotal),
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
                        Text(formatCurrency(s.price), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
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
