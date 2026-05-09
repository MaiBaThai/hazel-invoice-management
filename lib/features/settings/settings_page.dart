import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/settings_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../data/models/app_settings_model.dart';
import '../../data/models/invoice_model.dart';

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
          const SizedBox(height: 32),
          _buildBankConfigSection(context, provider),
          const SizedBox(height: 32),
          _buildServiceMenuSection(context, provider),
        ],
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
                        Text('${service.price}k', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pink)),
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
            TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price (k)'), keyboardType: TextInputType.number),
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
                        auth.isAnonymous ? 'Guest Mode' : 'Account Secured',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        auth.isAnonymous 
                          ? 'Login to sync and backup your data' 
                          : (auth.user?.email ?? 'Logged in'),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      if (const String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev') == 'dev') ...[
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
                          SnackBar(content: Text('Login failed: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('LINK WITH GOOGLE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
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
}
