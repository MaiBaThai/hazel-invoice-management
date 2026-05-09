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
  final String? userId;

  DatabaseService({this.userId});

  // --- Scoped References ---

  CollectionReference get _customersRef => userId == null 
      ? _db.collection('customers') 
      : _db.collection('users').doc(userId).collection('customers');

  CollectionReference get _invoicesRef => userId == null 
      ? _db.collection('invoices') 
      : _db.collection('users').doc(userId).collection('invoices');

  CollectionReference get _expensesRef => userId == null 
      ? _db.collection('expenses') 
      : _db.collection('users').doc(userId).collection('expenses');

  DocumentReference get _settingsRef => userId == null 
      ? _db.collection('configs').doc('app_settings')
      : _db.collection('users').doc(userId).collection('configs').doc('app_settings');

  Reference get _storageRoot => userId == null
      ? _storage.ref()
      : _storage.ref().child('users/$userId');

  // --- Customers ---
  
  Future<List<Customer>> getCustomers() async {
    final snapshot = await _customersRef.get();
    return snapshot.docs
        .map((doc) => Customer.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<Customer?> getCustomer(String customerId) async {
    final doc = await _customersRef.doc(customerId).get();
    if (doc.exists && doc.data() != null) {
      return Customer.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final lowerQuery = query.toLowerCase();
    
    // 1. Search by name (case-insensitive)
    final nameQuery = _customersRef
        .where('name_lowercase', isGreaterThanOrEqualTo: lowerQuery)
        .where('name_lowercase', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
        .get();

    // 2. Search by phone
    final phoneQuery = _customersRef
        .where('phone', isGreaterThanOrEqualTo: query)
        .where('phone', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    final results = await Future.wait([nameQuery, phoneQuery]);
    
    // Merge and remove duplicates
    final Map<String, Customer> merged = {};
    
    for (var snapshot in results) {
      for (var doc in snapshot.docs) {
        merged[doc.id] = Customer.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
    }

    return merged.values.toList();
  }

  Future<String> addCustomer(Customer customer) async {
    final docRef = await _customersRef.add(customer.toMap());
    return docRef.id;
  }

  Future<void> setCustomer(String id, Customer customer) async {
    await _customersRef.doc(id).set(customer.toMap());
  }

  Future<void> updateCustomer(String id, String name, String phone) async {
    await _customersRef.doc(id).update({
      'name': name,
      'name_lowercase': name.toLowerCase(),
      'phone': phone,
    });
  }

  Future<void> deleteCustomer(String customerId) async {
    final batch = _db.batch();
    
    // 1. Delete customer document
    batch.delete(_customersRef.doc(customerId));
    
    // 2. Delete all invoices for this customer
    final invoicesSnapshot = await _invoicesRef
        .where('customer_id', isEqualTo: customerId)
        .get();
        
    for (var doc in invoicesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  }

  // --- Invoices ---

  Future<String> saveInvoice(Invoice invoice) async {
    final invoiceRef = _invoicesRef.doc();
    final invoiceId = invoiceRef.id;

    await _db.runTransaction((transaction) async {
      // 1. Verify Customer exists
      final customerRef = _customersRef.doc(invoice.customerId);
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

  Future<void> setInvoice(String id, Invoice invoice) async {
    await _invoicesRef.doc(id).set(invoice.toMap());
  }

  // --- Storage ---

  Future<String> uploadInvoicePhoto(String invoiceId, String customerId, Uint8List bytes) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    // Logic: if userId is null, it goes to 'customers/...', if not it goes to 'users/uid/customers/...'
    final path = userId == null 
        ? 'customers/$customerId/invoices/$invoiceId/$fileName'
        : 'customers/$customerId/invoices/$invoiceId/$fileName'; // _storageRoot already handles prefix
    
    final ref = _storageRoot.child(path);
    
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'invoice_id': invoiceId,
        'customer_id': customerId,
        if (userId != null) 'user_id': userId!,
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
      final invoiceRef = _invoicesRef.doc(invoiceId);
      final doc = await invoiceRef.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
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
    await _invoicesRef.doc(invoiceId).update({
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
    final docRef = await _expensesRef.add(expense.toMap());
    return docRef.id;
  }

  Future<List<Expense>> getExpensesSince(DateTime date) async {
    final snapshot = await _expensesRef
        .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(date))
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Expense.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  // --- Reports ---

  Future<List<Invoice>> getInvoicesSince(DateTime date) async {
    final snapshot = await _invoicesRef
        .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(date))
        .orderBy('created_at', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Invoice.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<Invoice>> getCustomerInvoices(String customerId) async {
    final snapshot = await _invoicesRef
        .where('customer_id', isEqualTo: customerId)
        .get();

    final invoices = snapshot.docs
        .map((doc) => Invoice.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
        
    invoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return invoices;
  }

  // --- Settings ---

  Future<AppSettings> getSettings() async {
    try {
      final doc = await _settingsRef.get().timeout(const Duration(seconds: 5));
      if (doc.exists && doc.data() != null) {
        return AppSettings.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Error fetching settings: $e');
    }
    
    // Create/Return default settings if fetch fails or document doesn't exist
    final defaultSettings = AppSettings.defaultSettings();
    // Try to update/save if possible, but don't await indefinitely
    updateSettings(defaultSettings).catchError((e) => debugPrint('Error saving default settings: $e'));
    return defaultSettings;
  }

  Future<void> updateSettings(AppSettings settings) async {
    await _settingsRef.set(settings.toMap());
  }
}
