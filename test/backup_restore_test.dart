import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nms/data/services/database_service.dart';
import 'package:nms/data/services/migration_service.dart';
import 'package:nms/data/models/customer_model.dart';
import 'package:nms/data/models/invoice_model.dart';
import 'package:nms/data/models/expense_model.dart';
import 'package:nms/data/models/app_settings_model.dart';

void main() {
  group('Migration Tools - Web to iOS Backup & Restore Automation Tests', () {
    late FakeFirebaseFirestore fakeDb;
    late MigrationService migrationService;

    setUp(() {
      fakeDb = FakeFirebaseFirestore();
      migrationService = MigrationService(firestore: fakeDb);
    });

    test('End-to-End: Backup data from Web and Restore to iOS version', () async {
      const webUserId = 'web_user_123';
      const iosUserId = 'ios_user_456';

      // 1. Setup Source Data (Simulating Web App State)
      final webDb = DatabaseService(
        userId: webUserId,
        isAnonymous: false,
        firestore: fakeDb,
      );

      // Seed settings
      final originalSettings = AppSettings(
        businessConfig: BusinessConfig(
          businessName: 'Web Nail Spa',
          currencySymbol: '\$',
        ),
        bankConfig: BankConfig(
          bankName: 'Test Bank',
          accountNumber: '987654321',
          accountName: 'Web Owner',
        ),
        predefinedServices: [
          ServiceItem(serviceName: 'Manicure', price: 20000),
          ServiceItem(serviceName: 'Pedicure', price: 25000),
        ],
      );
      await webDb.updateSettings(originalSettings);

      // Seed Customer
      final originalCustomer = Customer(
        id: 'cust_abc_123',
        name: 'John Doe',
        phone: '0901234567',
        totalSpent: 40000,
      );
      await webDb.setCustomer(originalCustomer.id, originalCustomer);

      // Seed Invoice (with complex timestamps, nested service items, and photos)
      final createdAt = DateTime(2026, 6, 1, 10, 30);
      final sessionStart = DateTime(2026, 6, 1, 10, 00);
      final sessionEnd = DateTime(2026, 6, 1, 11, 00);
      final originalInvoice = Invoice(
        id: 'inv_xyz_789',
        customerId: originalCustomer.id,
        customerName: originalCustomer.name,
        services: [
          ServiceItem(serviceName: 'Manicure', price: 20000),
          ServiceItem(serviceName: 'Pedicure', price: 25000),
        ],
        subtotal: 45000,
        discountPercent: 10,
        finalTotal: 40500,
        photoUrls: ['https://example.com/photo1.jpg', 'https://example.com/photo2.jpg'],
        createdAt: createdAt,
        sessionStart: sessionStart,
        sessionEnd: sessionEnd,
      );
      await webDb.setInvoice(originalInvoice.id, originalInvoice);

      // Seed Expense (with itemized lists)
      final originalExpense = Expense(
        id: 'exp_111_222',
        items: [
          ExpenseItem(description: 'Supplies', cost: 15000),
          ExpenseItem(description: 'Electricity', cost: 5000),
        ],
        totalCost: 20000,
        note: 'June Utilities',
        createdAt: createdAt,
      );
      await webDb.setExpense(originalExpense.id, originalExpense);

      // Verify that data is correctly seeded in the source (web user)
      final sourceSettingsDoc = await fakeDb
          .collection('users')
          .doc(webUserId)
          .collection('configs')
          .doc('app_settings')
          .get();
      expect(sourceSettingsDoc.exists, isTrue);

      // 2. Perform Web Backup
      final Map<String, dynamic> exportedBackup = await migrationService.exportData(userId: webUserId);

      // Verify backup structure and format
      expect(exportedBackup['version'], equals('2.0.0'));
      expect(exportedBackup['user_id'], equals(webUserId));
      expect(exportedBackup['data'], isNotNull);
      
      final Map<String, dynamic> dataPayload = exportedBackup['data'] as Map<String, dynamic>;
      expect(dataPayload['customers'], isNotEmpty);
      expect(dataPayload['invoices'], isNotEmpty);
      expect(dataPayload['expenses'], isNotEmpty);
      expect(dataPayload['configs'], isNotEmpty);

      // Ensure that timestamps are fully serialized to ISO 8601 strings in the exported JSON map (platform independent representation)
      final invoiceBackup = dataPayload['invoices'].first as Map<String, dynamic>;
      expect(invoiceBackup['created_at'], isA<String>());
      expect(invoiceBackup['created_at'], equals(createdAt.toIso8601String()));
      expect(invoiceBackup['session_start'], equals(sessionStart.toIso8601String()));
      expect(invoiceBackup['session_end'], equals(sessionEnd.toIso8601String()));

      // 3. Perform iOS Restore
      // Restore the backup into the clean iOS user's account
      await migrationService.importDataFromJson(exportedBackup, targetUserId: iosUserId);

      // 4. Verify iOS Restored State
      final iosDb = DatabaseService(
        userId: iosUserId,
        isAnonymous: false,
        firestore: fakeDb,
      );

      // Verify Settings
      final restoredSettings = await iosDb.getSettings();
      expect(restoredSettings.businessConfig.businessName, equals('Web Nail Spa'));
      expect(restoredSettings.bankConfig.bankName, equals('Test Bank'));
      expect(restoredSettings.bankConfig.accountNumber, equals('987654321'));
      expect(restoredSettings.predefinedServices.length, equals(2));
      expect(restoredSettings.predefinedServices[0].serviceName, equals('Manicure'));

      // Verify Customer
      final restoredCustomers = await fakeDb
          .collection('users')
          .doc(iosUserId)
          .collection('customers')
          .get();
      expect(restoredCustomers.docs.length, equals(1));
      
      final restoredCustomer = Customer.fromMap(
        restoredCustomers.docs.first.id,
        restoredCustomers.docs.first.data(),
      );
      expect(restoredCustomer.id, equals(originalCustomer.id));
      expect(restoredCustomer.name, equals(originalCustomer.name));
      expect(restoredCustomer.phone, equals(originalCustomer.phone));
      expect(restoredCustomer.totalSpent, equals(originalCustomer.totalSpent));
      // Verify automatic search index generation during restore
      expect(restoredCustomers.docs.first.data()['name_lowercase'], equals('john doe'));

      // Verify Invoice (including precise nested structures and DateTime reconstruction from Timestamps)
      final restoredInvoices = await fakeDb
          .collection('users')
          .doc(iosUserId)
          .collection('invoices')
          .get();
      expect(restoredInvoices.docs.length, equals(1));

      final restoredInvoice = Invoice.fromMap(
        restoredInvoices.docs.first.id,
        restoredInvoices.docs.first.data(),
      );
      expect(restoredInvoice.id, equals(originalInvoice.id));
      expect(restoredInvoice.customerId, equals(originalInvoice.customerId));
      expect(restoredInvoice.customerName, equals(originalInvoice.customerName));
      expect(restoredInvoice.services.length, equals(2));
      expect(restoredInvoice.services[0].serviceName, equals('Manicure'));
      expect(restoredInvoice.services[0].price, equals(20000));
      expect(restoredInvoice.subtotal, equals(originalInvoice.subtotal));
      expect(restoredInvoice.discountPercent, equals(originalInvoice.discountPercent));
      expect(restoredInvoice.finalTotal, equals(originalInvoice.finalTotal));
      expect(restoredInvoice.photoUrls, containsAll(originalInvoice.photoUrls));
      
      // Verify Timestamps are correctly restored to DateTime
      expect(restoredInvoice.createdAt, equals(createdAt));
      expect(restoredInvoice.sessionStart, equals(sessionStart));
      expect(restoredInvoice.sessionEnd, equals(sessionEnd));

      // Verify Expense
      final restoredExpenses = await fakeDb
          .collection('users')
          .doc(iosUserId)
          .collection('expenses')
          .get();
      expect(restoredExpenses.docs.length, equals(1));

      final restoredExpense = Expense.fromMap(
        restoredExpenses.docs.first.id,
        restoredExpenses.docs.first.data(),
      );
      expect(restoredExpense.id, equals(originalExpense.id));
      expect(restoredExpense.totalCost, equals(originalExpense.totalCost));
      expect(restoredExpense.note, equals(originalExpense.note));
      expect(restoredExpense.items.length, equals(2));
      expect(restoredExpense.items[0].description, equals('Supplies'));
      expect(restoredExpense.items[0].cost, equals(15000));
      expect(restoredExpense.createdAt, equals(createdAt));
    });
  });
}
