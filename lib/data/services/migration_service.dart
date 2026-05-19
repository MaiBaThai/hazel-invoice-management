import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'database_service.dart';
import '../models/customer_model.dart';
import '../models/invoice_model.dart';
import '../models/expense_model.dart';
import '../models/app_settings_model.dart';

class MigrationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  /// Checks if a user is whitelisted for data migration or premium access.
  Future<bool> isUserWhitelisted(String email) async {
    try {
      final doc = await _db.collection('system_configs').doc('access_control').get();
      if (!doc.exists) return false;
      
      final whitelist = List<String>.from(doc.data()?['whitelisted_emails'] ?? []);
      return whitelist.contains(email.toLowerCase());
    } catch (e) {
      debugPrint('Error checking whitelist: $e');
      return false;
    }
  }

  /// Copies data from global collections to user-scoped collections without deleting.
  Future<void> copyLegacyData(String userId) async {
    final userScopedDb = DatabaseService(userId: userId);
    final globalDb = DatabaseService(userId: null);

    try {
      debugPrint('Starting manual copy for user: $userId');

      // 1. Copy Settings
      final globalSettings = await globalDb.getSettings();
      await userScopedDb.updateSettings(globalSettings);

      // 2. Copy Customers
      final customers = await globalDb.getCustomers();
      for (var customer in customers) {
        if (customer.id != null) {
          await userScopedDb.setCustomer(customer.id!, customer);
        }
      }

      // 3. Copy Invoices
      final invoices = await globalDb.getInvoicesSince(DateTime(2020));
      for (var invoice in invoices) {
        if (invoice.id != null) {
          await userScopedDb.setInvoice(invoice.id!, invoice);
        }
      }

      // 4. Copy Expenses
      final expenses = await globalDb.getExpensesSince(DateTime(2020));
      for (var expense in expenses) {
        if (expense.id != null) {
          await userScopedDb.saveExpense(expense);
        }
      }

      debugPrint('Data copied to user-scoped collections successfully.');
    } catch (e) {
      debugPrint('Copy failed: $e');
      rethrow;
    }
  }

  /// Deletes data from global collections after successful verification.
  Future<void> deleteLegacyData() async {
    try {
      debugPrint('Starting cleanup of global records...');
      
      // 1. Cleanup Customers
      final customers = await _db.collection('customers').get();
      for (var doc in customers.docs) {
        await doc.reference.delete();
      }

      // 2. Cleanup Invoices
      final invoices = await _db.collection('invoices').get();
      for (var doc in invoices.docs) {
        await doc.reference.delete();
      }

      // 3. Cleanup Expenses
      final expenses = await _db.collection('expenses').get();
      for (var doc in expenses.docs) {
        await doc.reference.delete();
      }

      debugPrint('Global records cleaned up successfully.');
    } catch (e) {
      debugPrint('Cleanup failed: $e');
      rethrow;
    }
  }

  /// Marks migration as completed for a specific user
  Future<void> markAsCompleted(String userId) async {
    await _db.collection('users').doc(userId).set({
      'migration_status': {
        'completed': true,
        'timestamp': FieldValue.serverTimestamp(),
        'source': 'manual_migration_v1.5.0',
      }
    }, SetOptions(merge: true));
  }

  /// Checks if the user has already migrated data.
  Future<bool> hasAlreadyMigrated(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.data()?['migration_status']?['completed'] == true;
  }
  /// Exports data from collections as a JSON-serializable Map.
  /// If [userId] is provided, it exports from user-scoped collections.
  /// If [userId] is null, it exports from global root collections (Admin only).
  Future<Map<String, dynamic>> exportData({String? userId}) async {
    try {
      final customersRef = userId == null ? _db.collection('customers') : _db.collection('users').doc(userId).collection('customers');
      final invoicesRef = userId == null ? _db.collection('invoices') : _db.collection('users').doc(userId).collection('invoices');
      final expensesRef = userId == null ? _db.collection('expenses') : _db.collection('users').doc(userId).collection('expenses');
      final configsRef = userId == null ? _db.collection('configs') : _db.collection('users').doc(userId).collection('configs');

      final customersSnapshot = await customersRef.get();
      final invoicesSnapshot = await invoicesRef.get();
      final expensesSnapshot = await expensesRef.get();
      final configsSnapshot = await configsRef.get();

      // Convert to models first to fill in missing fields with defaults
      final customers = customersSnapshot.docs.map((doc) {
        final model = Customer.fromMap(doc.id, doc.data());
        return {'id': doc.id, ..._prepareForJson(model.toMap())};
      }).toList();

      final invoices = invoicesSnapshot.docs.map((doc) {
        final model = Invoice.fromMap(doc.id, doc.data());
        return {'id': doc.id, ..._prepareForJson(model.toMap())};
      }).toList();

      final expenses = expensesSnapshot.docs.map((doc) {
        final model = Expense.fromMap(doc.id, doc.data());
        return {'id': doc.id, ..._prepareForJson(model.toMap())};
      }).toList();

      final List<Map<String, dynamic>> configs = [];
      for (var doc in configsSnapshot.docs) {
        if (doc.id == 'app_settings') {
          // Force use of AppSettings model to fill in missing fields from legacy data
          final settings = AppSettings.fromMap(doc.data());
          configs.add({'id': doc.id, ..._prepareForJson(settings.toMap())});
        } else {
          configs.add({'id': doc.id, ..._prepareForJson(doc.data())});
        }
      }

      return {
        'timestamp': DateTime.now().toIso8601String(),
        'version': '2.0.0', // New schema version
        'source': userId == null ? 'root_collections_backup' : 'user_scoped_backup',
        'user_id': userId,
        'data': {
          'customers': customers,
          'invoices': invoices,
          'expenses': expenses,
          'configs': configs,
        }
      };
    } catch (e) {
      debugPrint('Export failed: $e');
      rethrow;
    }
  }

  /// Recursively converts Firestore-specific types into JSON-serializable formats.
  dynamic _prepareForJson(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    } else if (value is DocumentReference) {
      return value.path;
    } else if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), _prepareForJson(v)));
    } else if (value is List) {
      return value.map((e) => _prepareForJson(e)).toList();
    }
    return value;
  }

  /// Imports data from a JSON Map into the specified target (Root or Scoped).
  Future<void> importDataFromJson(Map<String, dynamic> jsonData, {String? targetUserId}) async {
    final db = DatabaseService(userId: targetUserId);
    final data = jsonData['data'] as Map<String, dynamic>?;

    if (data == null) throw Exception('Invalid backup file: No data found');

    try {
      // 1. Restore Customers
      if (data['customers'] != null) {
        for (var item in data['customers']) {
          final id = item['id'];
          if (id != null) {
            final Map<String, dynamic> rawData = Map<String, dynamic>.from(item)..remove('id');
            final restoredData = _restoreFromJson(rawData) as Map<String, dynamic>;
            
            // Post-restore normalization for search fields
            if (!restoredData.containsKey('name_lowercase') && restoredData.containsKey('name')) {
              restoredData['name_lowercase'] = restoredData['name'].toString().toLowerCase();
            }
            
            await db.setCustomer(id, Customer.fromMap(id, restoredData));
          }
        }
      }

      // 2. Restore Invoices
      if (data['invoices'] != null) {
        for (var item in data['invoices']) {
          final id = item['id'];
          if (id != null) {
            final Map<String, dynamic> rawData = Map<String, dynamic>.from(item)..remove('id');
            final restoredData = _restoreFromJson(rawData) as Map<String, dynamic>;
            
            await db.setInvoice(id, Invoice.fromMap(id, restoredData));
          }
        }
      }

      // 3. Restore Expenses
      if (data['expenses'] != null) {
        for (var item in data['expenses']) {
          final id = item['id'];
          if (id != null) {
            final Map<String, dynamic> rawData = Map<String, dynamic>.from(item)..remove('id');
            final restoredData = _restoreFromJson(rawData) as Map<String, dynamic>;
            
            await db.setExpense(id, Expense.fromMap(id, restoredData));
          }
        }
      }

      // 4. Restore Configs
      if (data['configs'] != null) {
        for (var item in data['configs']) {
          if (item['id'] == 'app_settings') {
            final Map<String, dynamic> rawData = Map<String, dynamic>.from(item)..remove('id');
            final restoredData = _restoreFromJson(rawData) as Map<String, dynamic>;
            
            await db.updateSettings(AppSettings.fromMap(restoredData));
          }
        }
      }
    } catch (e) {
      debugPrint('Import failed: $e');
      rethrow;
    }
  }

  /// Recursively restores data types from JSON (e.g., ISO strings to Timestamp).
  dynamic _restoreFromJson(dynamic value) {
    if (value is String) {
      // Basic check for ISO 8601 date format
      if (RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}').hasMatch(value)) {
        try {
          return Timestamp.fromDate(DateTime.parse(value));
        } catch (_) {
          return value;
        }
      }
    } else if (value is Map) {
      final restoredMap = value.map((k, v) => MapEntry(k.toString(), _restoreFromJson(v)));
      // Crucial: Create a fresh Map<String, dynamic> to avoid internal cast errors on Web
      return Map<String, dynamic>.from(restoredMap);
    } else if (value is List) {
      return value.map((e) => _restoreFromJson(e)).toList();
    }
    return value;
  }

  /// Deletes all data associated with a user in Firestore and Storage.
  Future<void> deleteUserScopedData(String userId) async {
    try {
      debugPrint('Starting full data deletion for user: $userId');

      // 1. Delete Firestore collections
      final collections = ['customers', 'invoices', 'expenses', 'configs'];
      for (final collection in collections) {
        await _deleteCollectionInBatches(
          _db.collection('users').doc(userId).collection(collection),
        );
      }

      // 2. Delete the root user document
      await _db.collection('users').doc(userId).delete();

      // 3. Delete Storage files
      try {
        final storageRoot = DatabaseService(userId: userId).storageRoot;
        await _deleteStorageFolder(storageRoot);
      } catch (e) {
        debugPrint('Note: Error during storage cleanup (might be empty): $e');
      }

      debugPrint('User data deletion completed successfully.');
    } catch (e) {
      debugPrint('Deletion failed: $e');
      rethrow;
    }
  }

  Future<void> _deleteCollectionInBatches(CollectionReference collection) async {
    final snapshot = await collection.get();
    if (snapshot.docs.isEmpty) return;

    final batchSize = 500;
    for (var i = 0; i < snapshot.docs.length; i += batchSize) {
      final batch = _db.batch();
      final chunk = snapshot.docs.skip(i).take(batchSize);
      for (var doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _deleteStorageFolder(dynamic ref) async {
    // We use dynamic because Reference is from firebase_storage which might not be imported yet
    // But since DatabaseService uses it, we should be fine if we import it or use it via DatabaseService
    try {
      final result = await ref.listAll();
      
      // Delete all files in this directory
      for (final item in result.items) {
        await item.delete();
      }
      
      // Recursively delete subdirectories
      for (final prefix in result.prefixes) {
        await _deleteStorageFolder(prefix);
      }
    } catch (e) {
      debugPrint('Storage folder cleanup warning: $e');
    }
  }
}
