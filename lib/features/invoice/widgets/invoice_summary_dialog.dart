import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/invoice_provider.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/providers/customer_provider.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js;
import '../../../main.dart';
import '../../../data/models/app_settings_model.dart';

class InvoiceSummaryDialog extends StatefulWidget {
  const InvoiceSummaryDialog({super.key});

  @override
  State<InvoiceSummaryDialog> createState() => _InvoiceSummaryDialogState();
}

class _InvoiceSummaryDialogState extends State<InvoiceSummaryDialog> {
  final GlobalKey _globalKey = GlobalKey();

  Future<void> _saveInvoiceImage() async {
    try {
      final boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      // pixelRatio 2.0 is enough for readability as per user request to save storage
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      
      final pngBytes = byteData.buffer.asUint8List();
      final fileName = 'Invoice_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.png';

      if (kIsWeb) {
        final base64 = base64Encode(pngBytes);
        js.context.callMethod('eval', [
          '''
          var element = document.createElement('a');
          element.setAttribute('href', 'data:application/octet-stream;base64,' + '$base64');
          element.setAttribute('download', '$fileName');
          element.style.display = 'none';
          document.body.appendChild(element);
          element.click();
          document.body.removeChild(element);
          '''
        ]);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invoice image downloaded!')),
          );
        }
      } else {
        // Fallback for non-web if needed, for now we notify
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saving image is currently supported on Web only.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving invoice image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<InvoiceProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final bankConfig = settingsProvider.settings?.bankConfig;
    final businessConfig = settingsProvider.settings?.businessConfig ?? BusinessConfig(businessName: 'Hazel Nails', currencySymbol: 'k');
    
    final currencyFormat = NumberFormat.decimalPattern();
    
    String formatCurrency(num amount) {
      final formatted = currencyFormat.format(amount);
      return businessConfig.isPrefix ? '${businessConfig.currencySymbol}$formatted' : '$formatted${businessConfig.currencySymbol}';
    }
    
    // Extract short bank code for vietqr (e.g., 'MB Bank' -> 'MB')
    // A robust app would use a proper list of BINs, but here we simplify:
    final String fullBankName = bankConfig?.bankName ?? '';
    final String bankId = fullBankName.trim().split(' ').first; 
    
    final String accountNo = (bankConfig?.accountNumber ?? '').trim(); 
    final String accountName = (bankConfig?.accountName ?? '').trim();
    
    final bool hasBankInfo = bankId.isNotEmpty && accountNo.isNotEmpty;
    
    final double amountInVnd = provider.finalTotal * 1000;
    final String description = 'NMS ${provider.selectedCustomer?.name ?? ''}'.trim();
    
    // vietqr.io expects the bank BIN or short code (like 'MB', 'TCB', 'VCB')
    final String qrUrl = 'https://img.vietqr.io/image/$bankId-$accountNo-compact.png?amount=${amountInVnd.toInt()}&addInfo=$description&accountName=$accountName';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with Download Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('REVIEW INVOICE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.pink),
                    onPressed: _saveInvoiceImage,
                    tooltip: 'Save Invoice to Device',
                  ),
                ],
              ),
            ),
            
            // The Capturable Area
            Flexible(
              child: SingleChildScrollView(
                child: RepaintBoundary(
                  key: _globalKey,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Shop Header in Image
                        Center(
                          child: Column(
                            children: [
                              Text(businessConfig.businessName.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
                              Text(DateFormat('dd/MM/yyyy - HH:mm').format(DateTime.now()), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 16),
                              const Text('INVOICE', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black)),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                        
                        // Customer Info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('CUSTOMER', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                                Text(provider.selectedCustomer?.name ?? 'Guest', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            if (provider.selectedCustomer?.phone != null)
                              Text(provider.selectedCustomer!.phone, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(thickness: 1, color: Colors.black12),
                        ),
                        
                        // Services Table
                        ...provider.services.where((s) => s.serviceName.isNotEmpty).map((s) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(s.serviceName, style: const TextStyle(fontSize: 14))),
                              Text(formatCurrency(s.price), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        )),
                        
                        const SizedBox(height: 24),
                        
                        // Totals Area
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Subtotal', style: TextStyle(color: Colors.grey)),
                                  Text(formatCurrency(provider.subtotal)),
                                ],
                              ),
                              if (provider.discountPercent > 0) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Discount (${provider.discountPercent}%)', style: const TextStyle(color: Colors.red)),
                                    Text('-${formatCurrency(provider.subtotal * provider.discountPercent / 100)}', style: const TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ],
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  Text(formatCurrency(provider.finalTotal), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.pink)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Payment QR
                        if (hasBankInfo && businessConfig.enableVietQR) ...[
                          Center(
                            child: Column(
                              children: [
                                const Text('SCAN TO PAY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.grey)),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[200]!),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Image.network(qrUrl, width: 180, height: 180, fit: BoxFit.contain),
                                ),
                                const SizedBox(height: 8),
                                Text('VietQR - $fullBankName', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                Text('$accountNo - $accountName', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Center(
                          child: Text('--- Thank you for choosing ${businessConfig.businessName} ---', style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            // Footer Actions (Not in Image)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        if (provider.isEditing) {
                          Navigator.popUntil(context, (route) => route.isFirst);
                          mainNavKey.currentState?.switchTab(0);
                        }
                      },
                      child: const Text('EDIT'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: provider.isSaving ? null : () async {
                        final customerId = provider.selectedCustomer?.id;
                        final invoiceId = await provider.saveInvoice(context);
                        
                        if (invoiceId != null && customerId != null && context.mounted) {
                          Navigator.pop(context); // Close summary dialog
                          _showPhotoPrompt(context, invoiceId, customerId);
                          provider.reset(); // Now safe to reset
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: provider.isSaving 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(provider.isEditing ? 'UPDATE INVOICE' : 'CONFIRM & SAVE'),
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

  void _showPhotoPrompt(BuildContext context, String invoiceId, String customerId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Consumer<CustomerProvider>(
        builder: (context, provider, child) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.camera_alt, color: Colors.pink),
              SizedBox(width: 10),
              Text('Capture Work?'),
            ],
          ),
          content: provider.isUploadingPhoto 
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Uploading photo...'),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Would you like to take a photo of this work to save in the customer library?'),
                  if (provider.uploadError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Text(
                        'Error: ${provider.uploadError}',
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
          actions: provider.isUploadingPhoto ? [] : [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(provider.uploadError != null ? 'CLOSE' : 'LATER', style: const TextStyle(color: Colors.grey)),
            ),
            if (provider.uploadError == null)
              ElevatedButton(
                onPressed: () async {
                  await provider.uploadPhotoForInvoice(invoiceId, customerId);
                  if (context.mounted && provider.uploadError == null) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white),
                child: const Text('📷 TAKE PHOTO'),
              ),
            if (provider.uploadError != null)
              ElevatedButton(
                onPressed: () async {
                  await provider.uploadPhotoForInvoice(invoiceId, customerId);
                  if (context.mounted && provider.uploadError == null) {
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                child: const Text('RETRY'),
              ),
          ],
        ),
      ),
    );
  }
}
