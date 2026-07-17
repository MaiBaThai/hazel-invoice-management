import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/subscription_provider.dart';

class PaywallBottomSheet extends StatefulWidget {
  final String titleExplanation;
  final double topPadding;

  const PaywallBottomSheet({
    super.key,
    this.titleExplanation = "Unlock the ultimate invoicing experience",
    this.topPadding = 0.0,
  });

  static Future<void> show(BuildContext context,
      {String titleExplanation = "Unlock the ultimate invoicing experience"}) {
    final double topPadding = MediaQuery.of(context).padding.top;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          PaywallBottomSheet(
            titleExplanation: titleExplanation,
            topPadding: topPadding,
          ),
    );
  }

  @override
  State<PaywallBottomSheet> createState() => _PaywallBottomSheetState();
}

class _PaywallBottomSheetState extends State<PaywallBottomSheet> {
  Package? _selectedPackage;

  @override
  Widget build(BuildContext context) {
    final subProvider = context.watch<SubscriptionProvider>();
    final packages = subProvider.activePackages;

    // Automatically select the yearly package if available, else first package
    if (_selectedPackage == null && packages.isNotEmpty) {
      _selectedPackage = packages.firstWhere(
        (p) => p.packageType == PackageType.annual,
        orElse: () => packages.first,
      );
    }

    final isProcessing = subProvider.isProcessingPurchase;

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(28),
      ),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E1428), // Deep purple premium background
            ),
            padding: EdgeInsets.fromLTRB(
                16,
                (widget.topPadding > 0 ? widget.topPadding : 12.0) + 8,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Premium Header Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFFF4081), Color(0xFFFFB74D)],
                        ).createShader(bounds),
                        child: const Icon(
                          Icons.auto_awesome,
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Premium Access',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          foreground: Paint()
                            ..shader = const LinearGradient(
                              colors: [Color(0xFFFF4081), Color(0xFFFFB74D)],
                            ).createShader(
                                const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  Text(
                    widget.titleExplanation,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Features list
                  _buildFeatureRow(
                      Icons.electric_bolt_rounded,
                      "Unlimited Invoices & Expenses",
                      "Create and save as many invoices or expenses as you need without limits"),
                  _buildFeatureRow(
                      Icons.calendar_today_rounded,
                      "Manage Bookings",
                      "Schedule appointments, check conflicts, and sync with external calendars"),
                  _buildFeatureRow(
                      Icons.add_photo_alternate_rounded,
                      "Photo Journals",
                      "Attach multiple photos to invoices to document your nail work"),
                  _buildFeatureRow(
                      Icons.analytics_rounded,
                      "Advanced Analysis",
                      "Track business performance and revenue trends with deep insights"),

                  const SizedBox(height: 12),

                  if (subProvider.isLoading && !isProcessing)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child:
                            CircularProgressIndicator(color: Color(0xFFFF4081)),
                      ),
                    )
                  else if (packages.isEmpty && !isProcessing)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.wifi_off_rounded,
                              color: Colors.white70, size: 36),
                          const SizedBox(height: 8),
                          const Text(
                            "Subscriptions Offline",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Please configure your RevenueCat API key in Firestore or connect to the internet.",
                            style:
                                TextStyle(color: Colors.white60, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          if (subProvider.lastError != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.redAccent.withOpacity(0.3)),
                              ),
                              child: Text(
                                "Diagnostic Error:\n${subProvider.lastError}",
                                style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 12,
                                    fontFamily: 'monospace'),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  else
                    ...packages.map((package) => _buildPackageCard(package)),

                  const SizedBox(height: 16),

                  // Purchase Button
                  ElevatedButton(
                    onPressed: (packages.isEmpty || subProvider.isLoading)
                        ? null
                        : () async {
                            if (_selectedPackage == null) return;
                            final success = await subProvider
                                .purchasePackage(_selectedPackage!);
                            if (success && mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "🎉 Welcome to NMS Premium! Enjoy unlimited features."),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      "Could not complete purchase. Please try again."),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4081),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0xFFFF4081).withOpacity(0.4),
                    ),
                    child: subProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            "CONTINUE",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                  ),

                  const SizedBox(height: 12),

                  // Restore Purchases (Centered & Highlighted)
                  Center(
                    child: TextButton(
                      onPressed: subProvider.isLoading
                          ? null
                          : () async {
                              final success =
                                  await subProvider.restorePurchases();
                              if (success && mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "🎉 Purchases successfully restored!"),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "No previous purchases found to restore."),
                                    backgroundColor: Colors.orangeAccent,
                                  ),
                                );
                              }
                            },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        "Restore Purchases",
                        style: TextStyle(
                          color: Color(0xFFFF4081),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Terms & Privacy Links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => _launchUrl("https://invocie-management.web.app/terms.html"),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          "Terms of Use",
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10.5,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _launchUrl("https://invocie-management.web.app/privacy.html"),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          "Privacy Policy",
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 10.5,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: (widget.topPadding > 0 ? widget.topPadding : 12.0) + 4,
            right: 12,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 24),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          if (isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.6),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFFFF4081)),
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Processing Transaction...",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFF4081).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: const Color(0xFFFF4081),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(Package package) {
    final isSelected = _selectedPackage == package;
    final isYearly = package.packageType == PackageType.annual;

    // Custom label text logic
    String displayName = package.storeProduct.title;
    if (package.packageType == PackageType.monthly) {
      displayName = "Premium Monthly";
    } else if (package.packageType == PackageType.annual) {
      displayName = "Premium Yearly";
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPackage = package;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF4081) : Colors.white10,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Checkbox selection ring
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFFF4081) : Colors.white30,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFF4081),
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isYearly) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFB74D), Color(0xFFFFA726)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "SAVE 45%",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isYearly
                        ? "Only $pricePerMonth/month, billed annually"
                        : "Billed monthly, cancel anytime",
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              package.storeProduct.priceString,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get pricePerMonth {
    if (_selectedPackage == null) return "";
    final yearlyProduct = _selectedPackage!.storeProduct;
    final double monthlyPrice = yearlyProduct.price / 12.0;
    // Format to 2 decimal places with currency symbol
    String symbol = "";
    if (yearlyProduct.priceString.contains("\$")) {
      symbol = "\$";
      return "$symbol${monthlyPrice.toStringAsFixed(2)}";
    }
    // Handle Vietnamese currency (VND)
    if (yearlyProduct.priceString.contains("đ") ||
        yearlyProduct.priceString.toLowerCase().contains("vnd")) {
      final int monthlyInt = (yearlyProduct.price / 12.0).round();
      return "${_formatVnd(monthlyInt)}đ";
    }
    return monthlyPrice.toStringAsFixed(2);
  }

  String _formatVnd(int amount) {
    // Simple thousands separator format
    final String str = amount.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Could not launch $urlString: $e");
    }
  }
}
