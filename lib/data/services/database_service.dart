import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../models/customer_model.dart';
import '../models/invoice_model.dart';
import '../models/expense_model.dart';
import '../models/app_settings_model.dart';
import '../models/system_config_model.dart';
import '../models/booking_model.dart';


class DatabaseService {
  final FirebaseFirestore _db;
  final FirebaseStorage? _storageOverride;
  FirebaseStorage get _storage => _storageOverride ?? FirebaseStorage.instance;
  final String? userId;
  final bool isAnonymous;

  DatabaseService({
    this.userId,
    this.isAnonymous = false,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _storageOverride = storage;

  bool _userSynced = false;

  Future<void> _ensureUserSynced() async {
    if (userId == null) return;
    if (_userSynced) return;

    final userRef = _db.collection('users').doc(userId);
    await userRef.set({
      'uid': userId,
      'created_at': FieldValue.serverTimestamp(),
      'last_active': FieldValue.serverTimestamp(),
      'note': 'Auto-created on first write',
    }, SetOptions(merge: true));

    _userSynced = true;
  }
  
  // --- User Management ---
  
  /// Ensures the user document exists in Firestore to prevent "non-existent ancestor" UI issues.
  Future<void> syncUser() async {
    if (userId == null) return;
    if (isAnonymous) {
      debugPrint('DatabaseService: Skipping startup syncUser for anonymous user');
      return;
    }

    final userRef = _db.collection('users').doc(userId);
    final doc = await userRef.get();
    
    if (!doc.exists) {
      await userRef.set({
        'uid': userId,
        'created_at': FieldValue.serverTimestamp(),
        'last_active': FieldValue.serverTimestamp(),
        'note': 'Auto-created to ensure UI visibility',
      });
    } else {
      await userRef.update({
        'last_active': FieldValue.serverTimestamp(),
      });
    }
  }

  // --- Scoped References ---
  // If userId is null, we point to a non-existent 'guests/null' path to prevent
  // accidental leakage or fetching of global legacy data during state transitions.
  CollectionReference get _customersRef => userId == null 
      ? _db.collection('guests').doc('null').collection('customers') 
      : _db.collection('users').doc(userId).collection('customers');

  CollectionReference get _invoicesRef => userId == null 
      ? _db.collection('guests').doc('null').collection('invoices') 
      : _db.collection('users').doc(userId).collection('invoices');

  CollectionReference get _expensesRef => userId == null 
      ? _db.collection('guests').doc('null').collection('expenses') 
      : _db.collection('users').doc(userId).collection('expenses');

  CollectionReference get _bookingsRef => userId == null 
      ? _db.collection('guests').doc('null').collection('bookings') 
      : _db.collection('users').doc(userId).collection('bookings');


  DocumentReference get _settingsRef => userId == null 
      ? _db.collection('guests').doc('null').collection('configs').doc('app_settings')
      : _db.collection('users').doc(userId).collection('configs').doc('app_settings');

  Reference get storageRoot => userId == null
      ? _storage.ref().child('guests/null')
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
    await _ensureUserSynced();
    final docRef = await _customersRef.add(customer.toMap());
    return docRef.id;
  }

  Future<void> setCustomer(String id, Customer customer) async {
    await _ensureUserSynced();
    await _customersRef.doc(id).set(customer.toMap());
  }

  Future<void> updateCustomer(String id, String name, String phone) async {
    await _ensureUserSynced();
    await _customersRef.doc(id).update({
      'name': name,
      'name_lowercase': name.toLowerCase(),
      'phone': phone,
    });
  }

  Future<void> deleteCustomer(String customerId) async {
    await _ensureUserSynced();
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
    await _ensureUserSynced();
    final invoiceRef = _invoicesRef.doc();
    final invoiceId = invoiceRef.id;

    await _db.runTransaction((transaction) async {
      // 1. Verify Customer exists
      final customerRef = _customersRef.doc(invoice.customerId);
      final customerDoc = await transaction.get(customerRef);
      
      if (!customerDoc.exists) {
        throw Exception('Customer with ID ${invoice.customerId} does not exist. They may have been deleted.');
      }

      // Check if Settings exist, if not set default settings
      final settingsDoc = await transaction.get(_settingsRef);
      if (!settingsDoc.exists) {
        transaction.set(_settingsRef, AppSettings.defaultSettings().toMap());
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

  Future<void> updateInvoice(String invoiceId, Invoice newInvoice, double originalTotal) async {
    await _ensureUserSynced();
    final invoiceRef = _invoicesRef.doc(invoiceId);

    await _db.runTransaction((transaction) async {
      // 1. Verify Customer exists
      final customerRef = _customersRef.doc(newInvoice.customerId);
      final customerDoc = await transaction.get(customerRef);
      
      if (!customerDoc.exists) {
        throw Exception('Customer with ID ${newInvoice.customerId} does not exist. They may have been deleted.');
      }

      // 2. Update Invoice Document
      transaction.update(invoiceRef, newInvoice.toMap());

      // 3. Update Customer Total Spent (compute difference)
      final difference = newInvoice.finalTotal - originalTotal;
      if (difference != 0) {
        transaction.update(customerRef, {
          'total_spent': FieldValue.increment(difference),
        });
      }
    });
  }

  Future<void> setInvoice(String id, Invoice invoice) async {
    await _ensureUserSynced();
    await _invoicesRef.doc(id).set(invoice.toMap());
  }

  // --- Storage ---

  Future<String> uploadInvoicePhoto(String invoiceId, String customerId, Uint8List bytes) async {
    await _ensureUserSynced();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    // Logic: if userId is null, it goes to 'customers/...', if not it goes to 'users/uid/customers/...'
    final path = userId == null 
        ? 'customers/$customerId/invoices/$invoiceId/$fileName'
        : 'customers/$customerId/invoices/$invoiceId/$fileName'; // storageRoot already handles prefix
    
    final ref = storageRoot.child(path);
    
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

  Future<String> uploadLogo(Uint8List bytes, {String? oldLogoUrl}) async {
    await _ensureUserSynced();
    
    if (oldLogoUrl != null && oldLogoUrl.isNotEmpty) {
      try {
        await deleteLogo(oldLogoUrl);
      } catch (e) {
        debugPrint('Warning: Could not delete old logo: $e');
      }
    }

    final fileName = 'salon_logo_${DateTime.now().millisecondsSinceEpoch}.png';
    final ref = storageRoot.child('configs/$fileName');
    
    final metadata = SettableMetadata(
      contentType: 'image/png',
      customMetadata: {
        if (userId != null) 'user_id': userId!,
      },
    );

    final uploadTask = ref.putData(bytes, metadata);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> deleteLogo(String logoUrl) async {
    await _ensureUserSynced();
    try {
      final ref = _storage.refFromURL(logoUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting logo from storage: $e');
    }
  }

  Future<void> deleteInvoicePhoto(String invoiceId, String photoUrl) async {
    await _ensureUserSynced();
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
    await _ensureUserSynced();
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
    await _ensureUserSynced();
    final docRef = await _expensesRef.add(expense.toMap());
    return docRef.id;
  }

  Future<void> setExpense(String id, Expense expense) async {
    await _ensureUserSynced();
    await _expensesRef.doc(id).set(expense.toMap());
  }

  Future<void> deleteExpense(String expenseId) async {
    await _ensureUserSynced();
    await _expensesRef.doc(expenseId).delete();
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
    
    // Return default settings in-memory without saving them to Firestore automatically.
    return AppSettings.defaultSettings();
  }

  Future<void> updateSettings(AppSettings settings) async {
    await _ensureUserSynced();
    await _settingsRef.set(settings.toMap());
  }

  Future<int> getInvoiceCountForMonth(int year, int month) async {
    final startOfMonth = DateTime(year, month, 1);
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;
    final startOfNextMonth = DateTime(nextYear, nextMonth, 1);

    final snapshot = await _invoicesRef
        .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('created_at', isLessThan: Timestamp.fromDate(startOfNextMonth))
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  // --- Monetization & Access Control ---

  Stream<SystemConfig> watchSystemConfig() {
    return _db.collection('system_configs').doc('monetization').snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return SystemConfig.fromMap(snapshot.data()!);
      }
      return SystemConfig.defaultConfig();
    });
  }

  Stream<List<String>> watchWhitelistedEmails() {
    return _db.collection('system_configs').doc('access_control').snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data();
        if (data != null) {
          final list = data['whitelist_emails'] ?? data['whitelisted_emails'];
          if (list != null) {
            return List<String>.from(list);
          }
        }
      }
      return [];
    });
  }

  // --- Bookings & Scheduling ---

  Stream<List<Booking>> watchBookings() {
    return _bookingsRef.orderBy('start_time').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Booking.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<String> addBooking(Booking booking) async {
    await _ensureUserSynced();
    final docRef = await _bookingsRef.add(booking.toMap());
    return docRef.id;
  }

  Future<void> updateBooking(Booking booking) async {
    await _ensureUserSynced();
    await _bookingsRef.doc(booking.id).set(booking.toMap());
  }

  Future<void> deleteBooking(String bookingId) async {
    await _ensureUserSynced();
    await _bookingsRef.doc(bookingId).delete();
  }

  Stream<DocumentSnapshot> watchCalendarSettings() {
    return _db
        .collection('users')
        .doc(userId)
        .collection('configs')
        .doc('calendar_settings')
        .snapshots();
  }

  Future<void> updateCalendarSettings(Map<String, dynamic> data) async {
    await _ensureUserSynced();
    await _db
        .collection('users')
        .doc(userId)
        .collection('configs')
        .doc('calendar_settings')
        .set(data, SetOptions(merge: true));
  }
}
