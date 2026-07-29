import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/invoice_provider.dart';
import '../../core/providers/customer_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/subscription_provider.dart';
import '../subscription/subscription_settings_page.dart';
import '../../data/models/app_settings_model.dart';
import '../../data/models/invoice_model.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/utils/web_helper.dart' as web_helper;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;


class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isRestoring = false;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SettingsProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (provider.isLoading || provider.settings == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildAccountSection(context, authProvider),
          const SizedBox(height: 32),
          _buildSubscriptionSection(context),

          const SizedBox(height: 32),
          _buildBusinessConfigSection(context, provider),
          if (provider.settings!.businessConfig.enableVietQR) ...[
            const SizedBox(height: 32),
            _buildBankConfigSection(context, provider),
          ],
          const SizedBox(height: 32),
          _buildServiceMenuSection(context, provider),
          if (!authProvider.isAnonymous) ...[
            const SizedBox(height: 48),
            _buildDangerZoneSection(context, authProvider),
            const SizedBox(height: 32),
            _buildDataManagementSection(context, authProvider),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDataManagementSection(BuildContext context, AuthProvider auth) {
    return Card(
      elevation: 0,
      color: Colors.blue.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.blue),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.storage, color: Colors.blue),
                SizedBox(width: 8),
                Text('Data Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Backup your data to a local file or restore from a previous backup.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isExporting || _isRestoring ? null : () => _handleBackup(context, auth),
                    icon: _isExporting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download, size: 16),
                    label: Text(_isExporting ? 'BACKING UP...' : 'BACKUP DATA', style: const TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRestoring || _isExporting ? null : () => _handleRestore(context, auth),
                    icon: _isRestoring
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.upload, size: 16),
                    label: Text(_isRestoring ? 'RESTORING...' : 'RESTORE DATA', style: const TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessConfigSection(BuildContext context, SettingsProvider provider) {
    final businessConfig = provider.settings!.businessConfig;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.pink.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Business Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.pink),
                  onPressed: () => _showEditBusinessDialog(context, provider, businessConfig),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Business Name', businessConfig.businessName),
            _buildInfoRow('Currency', businessConfig.currencySymbol == 'k' ? 'k (1,000 VNĐ)' : '\$ (USD)'),
          ],
        ),
      ),
    );
  }

  Widget _buildBankConfigSection(BuildContext context, SettingsProvider provider) {
    final bankConfig = provider.settings!.bankConfig;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.pink.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('VietQR Bank Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.pink),
                  onPressed: () => _showEditBankDialog(context, provider, bankConfig),
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Bank Name', bankConfig.bankName),
            _buildInfoRow('Account Number', bankConfig.accountNumber),
            _buildInfoRow('Account Name', bankConfig.accountName),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceMenuSection(BuildContext context, SettingsProvider provider) {
    final services = provider.settings!.predefinedServices;
    final businessConfig = provider.settings?.businessConfig ?? BusinessConfig(businessName: 'My Salon', currencySymbol: '\$');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.pink.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Service Menu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.pink),
                  onPressed: () => _showEditServiceDialog(context, provider, null, -1),
                ),
              ],
            ),
            const Divider(),
            if (services.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No services defined. Add one!'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: services.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final service = services[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(service.serviceName),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          businessConfig.isPrefix ? '${businessConfig.currencySymbol}${service.price}' : '${service.price}${businessConfig.currencySymbol}', 
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pink)
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                          onPressed: () => _showEditServiceDialog(context, provider, service, index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () => provider.deleteService(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showEditBusinessDialog(BuildContext context, SettingsProvider provider, BusinessConfig current) {
    final businessNameCtrl = TextEditingController(text: current.businessName);
    String selectedCurrency = current.currencySymbol;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Business Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: businessNameCtrl, decoration: const InputDecoration(labelText: 'Business Name')),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCurrency,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: const [
                  DropdownMenuItem(value: 'k', child: Text('k (1,000 VNĐ)')),
                  DropdownMenuItem(value: '\$', child: Text('\$ (USD)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      selectedCurrency = val;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () {
                final newName = businessNameCtrl.text.isEmpty ? 'My Salon' : businessNameCtrl.text;

                void saveChanges() {
                  provider.updateBusinessConfig(BusinessConfig(
                    businessName: newName,
                    currencySymbol: selectedCurrency,
                  ));
                  Navigator.pop(context);
                }

                if (selectedCurrency != current.currencySymbol) {
                  showDialog(
                    context: context,
                    builder: (confirmContext) => AlertDialog(
                      title: const Text('Confirm Currency Change'),
                      content: const Text(
                        'Changing your currency settings will reformat all price displays.\n\n'
                        '⚠️ WARNING: Past invoices will NOT be converted mathematically (e.g. 30k will show as \$30).\n\n'
                        'Are you sure you want to proceed?'
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(confirmContext),
                          child: const Text('CANCEL'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(confirmContext);
                            saveChanges();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('CONFIRM'),
                        ),
                      ],
                    ),
                  );
                } else {
                  saveChanges();
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white),
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditBankDialog(BuildContext context, SettingsProvider provider, BankConfig current) {
    final bankNameCtrl = TextEditingController(text: current.bankName);
    final accountNumCtrl = TextEditingController(text: current.accountNumber);
    final accountNameCtrl = TextEditingController(text: current.accountName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Bank Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: bankNameCtrl, decoration: const InputDecoration(labelText: 'Bank Name (e.g. MB Bank)')),
            TextField(controller: accountNumCtrl, decoration: const InputDecoration(labelText: 'Account Number'), keyboardType: TextInputType.number),
            TextField(controller: accountNameCtrl, decoration: const InputDecoration(labelText: 'Account Name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              provider.updateBankConfig(BankConfig(
                bankName: bankNameCtrl.text,
                accountNumber: accountNumCtrl.text,
                accountName: accountNameCtrl.text,
              ));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showEditServiceDialog(BuildContext context, SettingsProvider provider, ServiceItem? current, int index) {
    final businessConfig = provider.settings?.businessConfig ?? BusinessConfig(businessName: 'My Salon', currencySymbol: '\$');
    final nameCtrl = TextEditingController(text: current?.serviceName ?? '');
    final priceCtrl = TextEditingController(text: current?.price.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(current == null ? 'Add Service' : 'Edit Service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Service Name')),
            TextField(controller: priceCtrl, decoration: InputDecoration(labelText: 'Price (${businessConfig.currencySymbol})'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceCtrl.text) ?? 0.0;
              final newService = ServiceItem(serviceName: nameCtrl.text, price: price);
              if (current == null) {
                provider.addService(newService);
              } else {
                provider.updateService(index, newService);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pink, foregroundColor: Colors.white),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context, AuthProvider auth) {
    final isAnonymous = auth.isAnonymous;
    return Card(
      elevation: 0,
      color: Colors.pink.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.pink.withOpacity(0.2)),
      ),
      child: Padding(
        padding: isAnonymous
            ? const EdgeInsets.all(16.0)
            : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: isAnonymous
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.pink,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Guest Mode',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Login to sync and backup your data',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            SelectableText(
                              'UID: ${auth.isInitializing ? "Loading..." : (auth.user?.uid ?? "Unknown")}',
                              style: TextStyle(color: Colors.pink[300], fontSize: 10, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  // 1. SIGN-UP (Link Current Data)
                  const Text(
                    'CREATE ACCOUNT (Sign Up & Sync)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.pink,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Link your current local customers and invoices to a new cloud account so they are saved securely.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),

                  // Google Sign-Up Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await auth.signInWithGoogle();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Account linked successfully!')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Link failed. If you already have an account, use Sign In below.')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.link),
                      label: const Text('SIGN UP WITH GOOGLE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),

                  // Apple Sign-Up Button (iOS only)
                  if (Theme.of(context).platform == TargetPlatform.iOS) ...[
                    const SizedBox(height: 8),
                    SignInWithAppleButton(
                      onPressed: () async {
                        try {
                          await auth.signInWithApple();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Account linked successfully with Apple!')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Link failed. If you already have an account, use Sign In below.')),
                            );
                          }
                        }
                      },
                      text: 'Sign up with Apple',
                      style: SignInWithAppleButtonStyle.black,
                      borderRadius: BorderRadius.circular(8),
                      height: 40,
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 8),

                  // 2. SIGN-IN (Switch to Existing Account)
                  const Text(
                    'ALREADY HAVE AN ACCOUNT? (Sign In)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Log in to retrieve your existing cloud-saved data. Note: Current local data will be replaced.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),

                  // Google Sign-In Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await auth.signInWithGoogleDirectly();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Login failed: $e')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('SIGN IN WITH GOOGLE'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),

                  // Apple Sign-In Button (iOS only)
                  if (Theme.of(context).platform == TargetPlatform.iOS) ...[
                    const SizedBox(height: 8),
                    SignInWithAppleButton(
                      onPressed: () async {
                        try {
                          await auth.signInWithAppleDirectly();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Login failed: $e')),
                            );
                          }
                        }
                      },
                      text: 'Sign in with Apple',
                      style: SignInWithAppleButtonStyle.black,
                      borderRadius: BorderRadius.circular(8),
                      height: 40,
                    ),
                  ],
                ],
              )
            : Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.pink,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          auth.user?.email ?? 'Account Secured',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () {
                            final uid = auth.user?.uid;
                            if (uid != null) {
                              Clipboard.setData(ClipboardData(text: uid));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('UID copied to clipboard!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'UID: ${_truncateUid(auth.user?.uid)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.copy_rounded,
                                size: 12,
                                color: Colors.grey[500],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _handleLogout(context, auth),
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    tooltip: 'Logout',
                  ),
                ],
              ),
      ),
    );
  }

  String _truncateUid(String? uid) {
    if (uid == null || uid.isEmpty) return 'Unknown';
    if (uid.length <= 10) return uid;
    return '${uid.substring(0, 6)}...${uid.substring(uid.length - 4)}';
  }

  Widget _buildSubscriptionSection(BuildContext context) {
    final subProvider = context.watch<SubscriptionProvider>();
    final isPremium = subProvider.isPremium;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFFFF4081),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SubscriptionSettingsPage()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4081).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFFFF4081),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Subscription Plan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF4081),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPremium ? 'Premium Active (Studio Tier)' : 'Solo (Free tier)',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, AuthProvider auth) async {
    final subProvider = context.read<SubscriptionProvider>();
    final isPremium = subProvider.isPremium;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: Text(
          isPremium
              ? 'Are you sure you want to logout?\n\nNote: Your Premium access is currently linked to this account. Logging out will return you to the free version on this device.'
              : 'Are you sure you want to logout?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('LOGOUT', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await auth.signOut();
      // Silently sign in anonymously to keep the app working
      await auth.signInSilently();
    }
  }

  Future<void> _handleBackup(BuildContext context, AuthProvider auth) async {
    if (auth.isAnonymous) return;
    if (_isRestoring || _isExporting) return;

    if (mounted) {
      setState(() {
        _isExporting = true;
      });
    }

    try {
      final data = await auth.migrationService.exportData(userId: auth.user!.uid);
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      
      if (kIsWeb) {
        final String userLabel = auth.user?.email?.split('@').first ?? auth.user!.uid.substring(0, 8);
        final String fileName = "nms_backup_${userLabel}_${DateTime.now().millisecondsSinceEpoch}.json";
        
        web_helper.downloadBackupWeb(jsonString, fileName);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup downloaded successfully!')));
        }
      } else {
        final String userLabel = auth.user?.email?.split('@').first ?? auth.user!.uid.substring(0, 8);
        final String fileName = "nms_backup_${userLabel}_${DateTime.now().millisecondsSinceEpoch}.json";
        
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/$fileName');
        await tempFile.writeAsString(jsonString);
        
        if (context.mounted) {
          final box = context.findRenderObject() as RenderBox?;
          final Rect? sharePositionOrigin = box != null 
              ? (box.localToGlobal(Offset.zero) & box.size) 
              : null;
              
          await Share.shareXFiles(
            [XFile(tempFile.path)],
            subject: 'NMS Backup $userLabel',
            sharePositionOrigin: sharePositionOrigin,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _handleRestore(BuildContext context, AuthProvider auth) async {
    if (_isRestoring || _isExporting) return;

    if (mounted) {
      setState(() {
        _isRestoring = true;
      });
    }

    try {
      if (kIsWeb) {
        web_helper.uploadBackupWeb(
          onSuccess: (jsonData) async {
            try {
              if (context.mounted) {
                await _performRestore(context, auth, jsonData);
              }
            } finally {
              if (mounted) {
                setState(() {
                  _isRestoring = false;
                });
              }
            }
          },
          onError: (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
            }
            if (mounted) {
              setState(() {
                _isRestoring = false;
              });
            }
          },
        );
      } else {
        try {
          final result = await FilePicker.pickFiles(
            type: FileType.any,
          );

          if (result == null || result.files.isEmpty) {
            return; // User canceled the picker
          }

          final file = result.files.first;
          final isJson = file.extension?.toLowerCase() == 'json' || file.name.toLowerCase().endsWith('.json');
          if (!isJson) {
            throw Exception('Please select a valid .json backup file.');
          }

          Map<String, dynamic> jsonData;
          if (file.path != null) {
            final content = await File(file.path!).readAsString();
            jsonData = jsonDecode(content);
          } else if (file.bytes != null) {
            final content = utf8.decode(file.bytes!);
            jsonData = jsonDecode(content);
          } else {
            throw Exception('No file data available.');
          }

          if (context.mounted) {
            await _performRestore(context, auth, jsonData);
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isRestoring = false;
            });
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red),
        );
      }
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }

  Future<void> _performRestore(BuildContext context, AuthProvider auth, Map<String, dynamic> jsonData) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Restore'),
        content: const Text('This will PERMANENTLY overwrite all your current data with the contents of the JSON file. This action cannot be undone. Proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('RESTORE NOW', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restoring data... Please wait.')));
      try {
        await auth.migrationService.importDataFromJson(jsonData, targetUserId: auth.user!.uid);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore successful!')));
          
          if (kIsWeb) {
            web_helper.reloadPageWeb();
          } else {
            // Reset key providers manually to reflect changes in UI
            Provider.of<InvoiceProvider>(context, listen: false).reset();
            Provider.of<CustomerProvider>(context, listen: false).loadCustomers(force: true);
            Provider.of<DashboardProvider>(context, listen: false).loadDashboardData();
            Provider.of<SettingsProvider>(context, listen: false).loadSettings();
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Restore failed: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildDangerZoneSection(BuildContext context, AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            'DANGER ZONE',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: Colors.red.withOpacity(0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.red.withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Delete Account & Data',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Permanently delete your account along with all associated customers, invoices, and settings. This action is irreversible.',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleDeleteAllData(context, auth),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('DELETE MY ACCOUNT & DATA', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleDeleteAllData(BuildContext context, AuthProvider auth) async {
    final TextEditingController confirmController = TextEditingController();
    bool isDeleting = false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Are you absolutely sure?', style: TextStyle(color: Colors.red)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This will PERMANENTLY DELETE your account and all your data. To protect your records, a backup will be downloaded or shared automatically before deletion.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Type "delete" below to confirm:'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmController,
                    decoration: const InputDecoration(
                      hintText: 'delete',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (val) => setState(() {}),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(context, false),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: confirmController.text.toLowerCase() == 'delete' && !isDeleting
                      ? () => Navigator.pop(context, true)
                      : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  child: const Text('BACKUP & DELETE ACCOUNT'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && context.mounted) {
      final rootNavigator = Navigator.of(context, rootNavigator: true);
      try {
        // 1. Show global loading
        showDialog(
          context: context,
          useRootNavigator: true,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.red)),
        );

        // 2. Trigger automatic backup
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating backup...')));
        await _handleBackup(context, auth);
        
        // Give a tiny delay for the download to trigger
        await Future.delayed(const Duration(seconds: 1));

        // 3. Delete account and data
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleting account & data...')));
        }
        
        await auth.deleteCurrentUserAccount();

        // 4. Cleanup
        rootNavigator.pop(); // Close loading indicator
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account and all associated data deleted successfully.'),
              duration: Duration(seconds: 3),
            ),
          );

          await Future.delayed(const Duration(seconds: 2));
          
          if (!context.mounted) return;
          if (kIsWeb) {
            web_helper.reloadPageWeb();
          } else {
            // Fallback for mobile: reset key providers manually
            Provider.of<InvoiceProvider>(context, listen: false).reset();
            Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
            Provider.of<DashboardProvider>(context, listen: false).loadDashboardData();
            Provider.of<SettingsProvider>(context, listen: false).loadSettings();
          }
        }
      } on FirebaseAuthException catch (e) {
        rootNavigator.pop(); // Close loading indicator
        if (e.code == 'requires-recent-login') {
          if (context.mounted) {
            showDialog(
              context: context,
              useRootNavigator: true,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Identity Verification Required'),
                content: const Text(
                  'For security, you must verify your identity to delete your account. '
                  'Please tap "Verify & Delete" to authenticate using your sign-in provider.'
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('CANCEL'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(dialogContext); // Close verification request dialog
                      
                      if (!context.mounted) return;
                      
                      // 1. Show loading indicator
                      showDialog(
                        context: context,
                        useRootNavigator: true,
                        barrierDismissible: false,
                        builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.red)),
                      );
                      
                      try {
                        // 2. Re-authenticate
                        await auth.reauthenticateCurrentUser();
                        
                        // 3. Retry account deletion
                        await auth.deleteCurrentUserAccount();
                        
                        // 4. Cleanup
                        rootNavigator.pop(); // Close loading indicator
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Account and all associated data deleted successfully.'),
                              duration: Duration(seconds: 3),
                            ),
                          );

                          await Future.delayed(const Duration(seconds: 2));
                          
                          if (!context.mounted) return;
                          if (kIsWeb) {
                            web_helper.reloadPageWeb();
                          } else {
                            Provider.of<InvoiceProvider>(context, listen: false).reset();
                            Provider.of<CustomerProvider>(context, listen: false).loadCustomers();
                            Provider.of<DashboardProvider>(context, listen: false).loadDashboardData();
                            Provider.of<SettingsProvider>(context, listen: false).loadSettings();
                          }
                        }
                      } catch (reauthErr) {
                        rootNavigator.pop(); // Close loading indicator
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Verification failed: $reauthErr'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('VERIFY & DELETE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Deletion failed: ${e.message ?? e.code}'), backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        rootNavigator.pop(); // Close loading indicator
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deletion failed: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }
}
