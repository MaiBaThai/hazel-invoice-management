import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'database_service.dart';

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

  /// Migrates data from global collections to user-scoped collections.
  Future<void> migrateLegacyData(String userId) async {
    final userScopedDb = DatabaseService(userId: userId);
    final globalDb = DatabaseService(userId: null); // Points to global collections

    try {
      debugPrint('Starting migration for user: $userId');

      // 1. Migrate Settings
      final globalSettings = await globalDb.getSettings();
      await userScopedDb.updateSettings(globalSettings);
      debugPrint('Settings migrated.');

      // 2. Migrate Customers
      final customers = await globalDb.getCustomers();
      for (var customer in customers) {
        if (customer.id != null) {
          await userScopedDb.setCustomer(customer.id!, customer);
          // Delete from global after migrating to user-scoped
          await globalDb.deleteCustomer(customer.id!);
        }
      }
      debugPrint('${customers.length} customers migrated.');

      // 3. Migrate Invoices
      final invoices = await globalDb.getInvoicesSince(DateTime(2020));
      for (var invoice in invoices) {
        if (invoice.id != null) {
          await userScopedDb.setInvoice(invoice.id!, invoice);
          // Delete from global - low level delete to avoid batch issues in DatabaseService.deleteInvoice
          await _db.collection('invoices').doc(invoice.id).delete();
        }
      }
      debugPrint('${invoices.length} invoices migrated.');

      // 4. Migrate Expenses
      final expenses = await globalDb.getExpensesSince(DateTime(2020));
      for (var expense in expenses) {
        if (expense.id != null) {
          await userScopedDb.saveExpense(expense); // Expenses don't have IDs in model usually, but we could use setExpense if needed
          await _db.collection('expenses').doc(expense.id).delete();
        }
      }
      debugPrint('${expenses.length} expenses migrated.');

      // 5. Mark migration as completed for this user
      await _db.collection('users').doc(userId).set({
        'migration_status': {
          'completed': true,
          'timestamp': FieldValue.serverTimestamp(),
          'source': 'global_migration_v1.5.0',
        }
      }, SetOptions(merge: true));

      debugPrint('Migration completed successfully.');
    } catch (e) {
      debugPrint('Migration failed: $e');
      rethrow;
    }
  }

  /// Checks if the user has already migrated data.
  Future<bool> hasAlreadyMigrated(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.data()?['migration_status']?['completed'] == true;
  }
}
