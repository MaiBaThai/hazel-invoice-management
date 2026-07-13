import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/subscription_provider.dart';
import 'paywall_bottom_sheet.dart';

class SubscriptionSettingsPage extends StatelessWidget {
  const SubscriptionSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final subProvider = context.watch<SubscriptionProvider>();
    final isPremium = subProvider.isPremium;
    final packages = subProvider.activePackages;
    final isProcessing = subProvider.isProcessingPurchase;

    return PopScope(
      canPop: !isProcessing,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: const Color(0xFF1E1428), // Deep purple theme
            appBar: AppBar(
              title: const Text(
                "My Subscription",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              backgroundColor: const Color(0xFF1E1428),
              elevation: 0,
              iconTheme: IconThemeData(
                  color: isProcessing ? Colors.white30 : Colors.white),
              automaticallyImplyLeading: !isProcessing,
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Current Plan Status card
                    _buildStatusCard(context, subProvider),
                    const SizedBox(height: 32),

                    if (!isPremium) ...[
                      // Premium Upgrade Header
                      const Text(
                        "Choose a Premium Plan",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Show paywall inline if unsubscribed
                      if (subProvider.isLoading && !isProcessing)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: CircularProgressIndicator(
                                color: Color(0xFFFF4081)),
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
                                style: TextStyle(
                                    color: Colors.white60, fontSize: 13),
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
                                        color:
                                            Colors.redAccent.withOpacity(0.3)),
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
                        ...packages.map((package) => _buildSettingsPackageCard(
                            context, subProvider, package)),

                      const SizedBox(height: 24),

                      TextButton(
                        onPressed: subProvider.isLoading
                            ? null
                            : () async {
                                final success =
                                    await subProvider.restorePurchases();
                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "🎉 Purchases successfully restored!"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "No previous purchases found to restore."),
                                      backgroundColor: Colors.orangeAccent,
                                    ),
                                  );
                                }
                              },
                        child: const Text(
                          "Restore Previous Purchases",
                          style: TextStyle(
                            color: Color(0xFFFF4081),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ] else ...[
                      // Settings options for Premium user
                      _buildPremiumDetailsList(context, subProvider),
                    ],

                    const SizedBox(height: 40),

                    // Support or standard info text
                    const Center(
                      child: Text(
                        "For questions or receipt inquiries, please contact support email",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white30,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 24),
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D1F3D),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Color(0xFFFF4081)),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "Processing Transaction",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Please confirm payment and wait a moment. Do not close the app.",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
      BuildContext context, SubscriptionProvider subProvider) {
    final isPremium = subProvider.isPremium;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium
              ? [const Color(0xFFFF4081), const Color(0xFFFF80AB)]
              : [
                  Colors.white.withOpacity(0.06),
                  Colors.white.withOpacity(0.03)
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPremium ? const Color(0xFFFF4081) : Colors.white10,
        ),
        boxShadow: isPremium
            ? [
                BoxShadow(
                  color: const Color(0xFFFF4081).withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPremium ? "STUDIO TIER" : "SOLO TIER",
                style: TextStyle(
                  color: isPremium ? Colors.white : Colors.white60,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              Icon(
                isPremium ? Icons.auto_awesome : Icons.person_outline_rounded,
                color: isPremium ? Colors.white : Colors.white70,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isPremium ? "Premium Active" : "Free Plan",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPremium
                ? "You have complete, unrestricted access to all Premium features."
                : "You are currently using the limited Free version. Upgrade to unlock all features.",
            style: TextStyle(
              color:
                  isPremium ? Colors.white.withOpacity(0.85) : Colors.white54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPackageCard(
      BuildContext context, SubscriptionProvider subProvider, Package package) {
    final isYearly = package.packageType == PackageType.annual;
    String title = package.packageType == PackageType.monthly
        ? "Monthly Plan"
        : "Yearly Plan";
    String description = isYearly
        ? "Yearly plan with unlimited invoices & photos"
        : "Month-to-month access, cancel anytime";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isYearly) ...[
                      const SizedBox(width: 8),
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
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  package.storeProduct.priceString,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: subProvider.isLoading
                ? null
                : () async {
                    final success = await subProvider.purchasePackage(package);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("🎉 Welcome to NMS Premium!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4081),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Select"),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumDetailsList(
      BuildContext context, SubscriptionProvider subProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Subscription Management",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle_rounded,
                    color: Colors.greenAccent),
                title: const Text("Entitlement Active",
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text(
                    "Unlimited Invoices & Photo Journals unlocked.",
                    style: TextStyle(color: Colors.white54)),
              ),
              const Divider(color: Colors.white10, height: 1),
              ListTile(
                leading:
                    const Icon(Icons.settings_outlined, color: Colors.white60),
                title: const Text("Manage on App Store",
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text(
                    "Cancel, switch or change billing options.",
                    style: TextStyle(color: Colors.white54)),
                trailing: const Icon(Icons.open_in_new_rounded,
                    size: 18, color: Colors.white60),
                onTap: () async {
                  try {
                    final Uri url = Uri.parse(
                        "https://apps.apple.com/account/subscriptions");
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url,
                          mode: LaunchMode.externalApplication);
                    }
                  } catch (e) {
                    debugPrint("Could not open subscriptions: $e");
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
