import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/customer_model.dart';
import '../models/invoice_model.dart';
import '../models/expense_model.dart';
import '../models/app_settings_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- Customers ---
  
  Future<List<Customer>> getCustomers() async {
    final snapshot = await _db.collection('customers').get();
    return snapshot.docs
        .map((doc) => Customer.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<Customer?> getCustomer(String customerId) async {
    final doc = await _db.collection('customers').doc(customerId).get();
    if (doc.exists && doc.data() != null) {
      return Customer.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final lowerQuery = query.toLowerCase();
    
    // 1. Search by name (case-insensitive)
    final nameQuery = _db
        .collection('customers')
        .where('name_lowercase', isGreaterThanOrEqualTo: lowerQuery)
        .where('name_lowercase', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
        .get();

    // 2. Search by phone
    final phoneQuery = _db
        .collection('customers')
        .where('phone', isGreaterThanOrEqualTo: query)
        .where('phone', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    final results = await Future.wait([nameQuery, phoneQuery]);
    
    // Merge and remove duplicates
    final Map<String, Customer> merged = {};
    
    for (var snapshot in results) {
      for (var doc in snapshot.docs) {
        merged[doc.id] = Customer.fromMap(doc.id, doc.data());
      }
    }

    return merged.values.toList();
  }

  Future<String> addCustomer(Customer customer) async {
    final docRef = await _db.collection('customers').add(customer.toMap());
    return docRef.id;
  }

  Future<void> updateCustomer(String id, String name, String phone) async {
    await _db.collection('customers').doc(id).update({
      'name': name,
      'name_lowercase': name.toLowerCase(),
      'phone': phone,
    });
  }

  Future<void> deleteCustomer(String customerId) async {
    final batch = _db.batch();
    
    // 1. Delete customer document
    final customerRef = _db.collection('customers').doc(customerId);
    batch.delete(customerRef);
    
    // 2. Delete all invoices for this customer
    final invoicesSnapshot = await _db
        .collection('invoices')
        .where('customer_id', isEqualTo: customerId)
        .get();
        
    for (var doc in invoicesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  // --- Invoices ---

  Future<String> saveInvoice(Invoice invoice) async {
    final invoiceRef = _db.collection('invoices').doc();
    final invoiceId = invoiceRef.id;

    await _db.runTransaction((transaction) async {
      // 1. Verify Customer exists
      final customerRef = _db.collection('customers').doc(invoice.customerId);
      final customerDoc = await transaction.get(customerRef);
      
      if (!customerDoc.exists) {
        throw Exception('Customer with ID ${invoice.customerId} does not exist. They may have been deleted.');
      }

      // 2. Create Invoice Document
      transaction.set(invoiceRef, invoice.toMap());

      // 3. Update Customer Total Spent & Last Visit
      transaction.update(customerRef, {
        'total_spent': FieldValue.increment(invoice.finalTotal),
        'last_visit': Timestamp.fromDate(invoice.createdAt),
      });
    });

    return invoiceId;
  }

  // --- Storage ---

  Future<String> uploadInvoicePhoto(String invoiceId, String customerId, Uint8List bytes) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('customers/$customerId/invoices/$invoiceId/$fileName');
    
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'invoice_id': invoiceId,
        'customer_id': customerId,
      },
    );

    final uploadTask = ref.putData(bytes, metadata);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> deleteInvoicePhoto(String invoiceId, String photoUrl) async {
    try {
      // 1. Delete from Storage
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();

      // 2. Remove from Firestore invoice document
      final invoiceRef = _db.collection('invoices').doc(invoiceId);
      final doc = await invoiceRef.get();
      if (doc.exists) {
        final data = doc.data()!;
        final List<dynamic> photos = data['photoUrls'] ?? data['photo_urls'] ?? [];
        photos.remove(photoUrl);
        await invoiceRef.update({
          'photoUrls': photos,
          'photo_urls': FieldValue.delete(), // Remove old field name if exists
        });
      }
    } catch (e) {
      throw Exception('Error deleting photo: $e');
    }
  }

  Future<void> updateInvoicePhotos(String invoiceId, List<String> photoUrls) async {
    await _db.collection('invoices').doc(invoiceId).update({
      'photoUrls': FieldValue.arrayUnion(photoUrls),
    });
  }

  Future<void> deletePhoto(String photoUrl) async {
    try {
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting photo from storage: $e');
    }
  }

  // --- Expenses ---

  Future<String> saveExpense(Expense expense) async {
    final docRef = await _db.collection('expenses').add(expense.toMap());
    return docRef.id;
  }

  Future<List<Expense>> getExpensesSince(DateTime date) async {
    final snapshot = await _db
        .collection('expenses')
        .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(date))
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Expense.fromMap(doc.id, doc.data()))
        .toList();
  }

  // --- Reports (For Phase 2) ---

  Future<List<Invoice>> getInvoicesSince(DateTime date) async {
    final snapshot = await _db
        .collection('invoices')
        .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(date))
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Invoice.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<Invoice>> getCustomerInvoices(String customerId) async {
    final snapshot = await _db
        .collection('invoices')
        .where('customer_id', isEqualTo: customerId)
        .get();

    final invoices = snapshot.docs
        .map((doc) => Invoice.fromMap(doc.id, doc.data()))
        .toList();
        
    invoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return invoices;
  }

  // --- Settings (For Phase 3) ---

  Future<AppSettings> getSettings() async {
    final doc = await _db.collection('configs').doc('app_settings').get();
    if (doc.exists && doc.data() != null) {
      return AppSettings.fromMap(doc.data()!);
    } else {
      // Create default settings if none exist
      final defaultSettings = AppSettings.defaultSettings();
      await updateSettings(defaultSettings);
      return defaultSettings;
    }
  }

  Future<void> updateSettings(AppSettings settings) async {
    await _db.collection('configs').doc('app_settings').set(settings.toMap());
  }
}
