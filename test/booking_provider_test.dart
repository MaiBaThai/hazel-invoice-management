import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nms/core/providers/booking_provider.dart';
import 'package:nms/data/services/database_service.dart';
import 'package:nms/data/models/booking_model.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockGoogleSignInAuthorizationClient extends Mock implements GoogleSignInAuthorizationClient {}

void main() {
  group('BookingProvider Tests', () {
    late FakeFirebaseFirestore fakeDb;
    late DatabaseService dbService;
    late MockGoogleSignIn mockGoogleSignIn;
    late MockGoogleSignInAuthorizationClient mockAuthClient;
    late BookingProvider bookingProvider;

    setUp(() async {
      fakeDb = FakeFirebaseFirestore();
      dbService = DatabaseService(
        userId: 'user_123',
        isAnonymous: false,
        firestore: fakeDb,
      );
      mockGoogleSignIn = MockGoogleSignIn();
      mockAuthClient = MockGoogleSignInAuthorizationClient();

      when(() => mockGoogleSignIn.authorizationClient).thenReturn(mockAuthClient);
      when(() => mockAuthClient.authorizationHeaders(any(), promptIfNecessary: any(named: 'promptIfNecessary')))
          .thenAnswer((_) async => null);

      bookingProvider = BookingProvider(dbService, googleSignIn: mockGoogleSignIn);

      // Wait a moment for firestore listeners to initialize
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('watchBookings: should load bookings from Firestore', () async {
      final now = DateTime(2026, 7, 13, 10, 0);
      final bookingMap = {
        'title': 'Test Booking',
        'start_time': Timestamp.fromDate(now),
        'end_time': Timestamp.fromDate(now.add(const Duration(hours: 1))),
        'notes': 'Some notes',
        'customer_id': 'cust_1',
        'customer_name': 'Alice',
        'customer_phone': '123456789',
        'created_at': Timestamp.fromDate(now),
        'updated_at': Timestamp.fromDate(now),
      };

      await fakeDb
          .collection('users')
          .doc('user_123')
          .collection('bookings')
          .add(bookingMap);

      // Wait for stream updates
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bookingProvider.bookings.length, equals(1));
      expect(bookingProvider.bookings.first.title, equals('Test Booking'));
      expect(bookingProvider.bookings.first.customerName, equals('Alice'));
    });

    test('getConflicts: should correctly identify overlapping bookings', () async {
      final baseTime = DateTime(2026, 7, 13, 14, 0); // 14:00

      // Add a booking from 14:00 to 15:00
      final b1 = Booking(
        id: 'booking_1',
        title: 'Booking 1',
        startTime: baseTime,
        endTime: baseTime.add(const Duration(hours: 1)),
        notes: '',
        createdAt: baseTime,
        updatedAt: baseTime,
      );

      // Simulate bookings list in provider
      await dbService.addBooking(b1);
      await Future.delayed(const Duration(milliseconds: 100));

      // Test Case A: Entirely before (13:00 - 14:00) -> no conflict
      final conflictA = bookingProvider.getConflicts(
        baseTime.subtract(const Duration(hours: 1)),
        baseTime,
      );
      expect(conflictA.isEmpty, isTrue);

      // Test Case B: Overlap start (13:30 - 14:30) -> conflict
      final conflictB = bookingProvider.getConflicts(
        baseTime.subtract(const Duration(minutes: 30)),
        baseTime.add(const Duration(minutes: 30)),
      );
      expect(conflictB.length, equals(1));
      expect(conflictB.first.id, isNotEmpty);

      // Test Case C: Overlap end (14:30 - 15:30) -> conflict
      final conflictC = bookingProvider.getConflicts(
        baseTime.add(const Duration(minutes: 30)),
        baseTime.add(const Duration(minutes: 90)),
      );
      expect(conflictC.length, equals(1));

      // Test Case D: Inside (14:15 - 14:45) -> conflict
      final conflictD = bookingProvider.getConflicts(
        baseTime.add(const Duration(minutes: 15)),
        baseTime.add(const Duration(minutes: 45)),
      );
      expect(conflictD.length, equals(1));

      // Test Case E: Exclude current booking ID -> no conflict
      final conflictE = bookingProvider.getConflicts(
        baseTime.add(const Duration(minutes: 15)),
        baseTime.add(const Duration(minutes: 45)),
        excludeId: bookingProvider.bookings.first.id,
      );
      expect(conflictE.isEmpty, isTrue);
    });

    test('createBooking: should add booking to Firestore', () async {
      final now = DateTime.now();
      final newBooking = Booking(
        id: '',
        title: 'New Client Appointment',
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        notes: 'Needs sơn gel and massage',
        customerId: 'cust_999',
        customerName: 'Vy',
        customerPhone: '0987654321',
        createdAt: now,
        updatedAt: now,
      );

      await bookingProvider.createBooking(newBooking);
      await Future.delayed(const Duration(milliseconds: 100));

      final bookingsSnapshot = await fakeDb
          .collection('users')
          .doc('user_123')
          .collection('bookings')
          .get();

      expect(bookingsSnapshot.docs.length, equals(1));
      expect(bookingsSnapshot.docs.first.data()['title'], equals('New Client Appointment'));
      expect(bookingsSnapshot.docs.first.data()['customer_name'], equals('Vy'));
    });
  });
}
