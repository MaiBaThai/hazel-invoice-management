import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/invoice_provider.dart';
import '../../core/providers/customer_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../data/models/app_settings_model.dart';
import '../../data/models/invoice_model.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/utils/web_helper.dart' as web_helper;

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
          if (!authProvider.isAnonymous) ...[
            const SizedBox(height: 32),
            _buildDataManagementSection(context, authProvider),
          ],

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
                    onPressed: () => _handleBackup(context, auth),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('BACKUP DATA', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleRestore(context, auth),
                    icon: const Icon(Icons.upload, size: 16),
                    label: const Text('RESTORE DATA', style: TextStyle(fontSize: 11)),
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
    return Card(
      elevation: 0,
      color: Colors.pink.withOpacity(0.05),
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
                      Text(
                        auth.isAnonymous ? 'Guest Mode' : (auth.user?.email ?? 'Account Secured'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        auth.isAnonymous 
                          ? 'Login to sync and backup your data' 
                          : 'UID: ${auth.user?.uid ?? "Unknown"}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      if (auth.isAnonymous) ...[
                        const SizedBox(height: 4),
                        SelectableText(
                          'UID: ${auth.isInitializing ? "Loading..." : (auth.user?.uid ?? "Unknown")}',
                          style: TextStyle(color: Colors.pink[300], fontSize: 10, fontFamily: 'monospace'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (auth.isAnonymous) ...[
              const SizedBox(height: 16),
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
              const SizedBox(height: 8),
              Center(
                child: TextButton(
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
                  child: const Text('ALREADY HAVE AN ACCOUNT? SIGN IN'),
                ),
              ),
            ] else ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _handleLogout(context, auth),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('LOGOUT', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, AuthProvider auth) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
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
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Backup Data (JSON)'),
              content: SingleChildScrollView(child: SelectableText(jsonString)),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
      }
    }
  }

  Future<void> _handleRestore(BuildContext context, AuthProvider auth) async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore is only supported on Web version.')));
      return;
    }

    web_helper.uploadBackupWeb(
      onSuccess: (jsonData) async {
        if (!context.mounted) return;

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
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
            }
          }
        }
      },
      onError: (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
        }
      },
    );
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
                      'Delete All Data',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Permanently delete all customers, invoices, and settings associated with this account. This action is irreversible.',
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
                    child: const Text('DELETE ALL MY DATA', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    'This will PERMANENTLY DELETE all your data. To protect you, a backup will be downloaded automatically before deletion.',
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
                  child: const Text('BACKUP & DELETE EVERYTHING'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && context.mounted) {
      try {
        // 1. Show global loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.red)),
        );

        // 2. Trigger automatic backup
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating backup...')));
        await _handleBackup(context, auth);
        
        // Give a tiny delay for the download to trigger
        await Future.delayed(const Duration(seconds: 1));

        // 3. Delete everything
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleting data...')));
        }
        
        await auth.migrationService.deleteUserScopedData(auth.user!.uid);

          // 4. Cleanup
          if (context.mounted) {
            Navigator.pop(context); // Close loading indicator
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('All data deleted successfully. Your account remains active.'),
                duration: Duration(seconds: 3),
              ),
            );

            await Future.delayed(const Duration(seconds: 2));
            
            // A full reload is still the safest way to ensure NO stale state remains.
            // This time the user stays logged in with their account.
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
        } catch (e) {
          if (context.mounted) {
            Navigator.pop(context); // Close loading indicator
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deletion failed: $e'), backgroundColor: Colors.red));
          }
      }
    }
  }
}
