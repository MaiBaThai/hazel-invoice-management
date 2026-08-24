import 'dart:convert';
import 'dart:collection';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nms/core/providers/booking_provider.dart';
import 'package:nms/data/services/database_service.dart';
import 'package:nms/data/models/booking_model.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class MockGoogleSignIn extends Mock implements GoogleSignIn {}
class MockGoogleSignInAuthorizationClient extends Mock implements GoogleSignInAuthorizationClient {}
class MockHttpClient extends Mock implements http.Client {}
class MockDeviceCalendarPlugin extends Mock implements DeviceCalendarPlugin {}

class FakeBaseRequest extends Fake implements http.BaseRequest {}
class FakeRetrieveEventsParams extends Fake implements RetrieveEventsParams {}

void main() {
  tz.initializeTimeZones();

  setUpAll(() {
    registerFallbackValue(FakeBaseRequest());
    registerFallbackValue(FakeRetrieveEventsParams());
  });

  group('Two-Way Calendar Sync Tests', () {
    late FakeFirebaseFirestore fakeDb;
    late DatabaseService dbService;
    late MockGoogleSignIn mockGoogleSignIn;
    late MockGoogleSignInAuthorizationClient mockAuthClient;
    late MockHttpClient mockHttpClient;
    late MockDeviceCalendarPlugin mockDeviceCalendarPlugin;
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
      mockHttpClient = MockHttpClient();
      mockDeviceCalendarPlugin = MockDeviceCalendarPlugin();

      when(() => mockDeviceCalendarPlugin.hasPermissions()).thenAnswer((_) async => Result<bool>()..data = true);
      when(() => mockDeviceCalendarPlugin.retrieveCalendars()).thenAnswer((_) async => Result<UnmodifiableListView<Calendar>>()..data = UnmodifiableListView<Calendar>([]));
      when(() => mockDeviceCalendarPlugin.retrieveEvents(any(), any())).thenAnswer((_) async => Result<UnmodifiableListView<Event>>()..data = UnmodifiableListView<Event>([]));

      when(() => mockGoogleSignIn.authorizationClient).thenReturn(mockAuthClient);
      when(() => mockAuthClient.authorizationHeaders(any(), promptIfNecessary: any(named: 'promptIfNecessary')))
          .thenAnswer((_) async => {'Authorization': 'Bearer test_token'});

      final emptyResponseJson = jsonEncode({'items': []});
      when(() => mockHttpClient.send(any())).thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode(emptyResponseJson)),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      bookingProvider = BookingProvider(
        dbService,
        googleSignIn: mockGoogleSignIn,
        deviceCalendarPlugin: mockDeviceCalendarPlugin,
      );
      bookingProvider.mockHttpClient = mockHttpClient;

      // Seed settings in DB to enable sync
      await fakeDb
          .collection('users')
          .doc('user_123')
          .collection('configs')
          .doc('calendar_settings')
          .set({
        'google_sync_enabled': true,
        'apple_sync_enabled': true,
        'apple_calendar_id': 'apple_cal_123',
      });

      // Wait for listeners to pick up settings
      await Future.delayed(const Duration(milliseconds: 100));
    });

    test('syncExternalCalendars - Google: Adds new event, updates existing, and deletes removed', () async {
      // 1. Stub Google Calendar API returning 1 new event and 1 existing event
      final syncTime = DateTime(2026, 7, 29, 10, 0);
      final newEventTime = syncTime.add(const Duration(days: 2));
      final existingEventTime = syncTime.add(const Duration(days: 4));

      // Add existing booking to local Firestore
      final existingBooking = Booking(
        id: 'existing_booking_id',
        title: 'Old Title',
        startTime: existingEventTime,
        endTime: existingEventTime.add(const Duration(hours: 1)),
        notes: 'Old notes',
        googleEventId: 'g_event_exist',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await dbService.addBooking(existingBooking);

      // Add another booking that will be DELETED because it's in sync range but missing from external events
      final deleteEventTime = syncTime.add(const Duration(days: 5));
      final deleteBooking = Booking(
        id: 'delete_booking_id',
        title: 'Delete Me',
        startTime: deleteEventTime,
        endTime: deleteEventTime.add(const Duration(hours: 1)),
        notes: '',
        googleEventId: 'g_event_delete',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await dbService.addBooking(deleteBooking);
      await Future.delayed(const Duration(milliseconds: 100));

      final responseJson = jsonEncode({
        'items': [
          {
            'id': 'g_event_new',
            'summary': 'New Event Title',
            'description': 'New notes',
            'status': 'confirmed',
            'start': {'dateTime': newEventTime.toUtc().toIso8601String()},
            'end': {'dateTime': newEventTime.add(const Duration(hours: 1)).toUtc().toIso8601String()},
          },
          {
            'id': 'g_event_exist',
            'summary': 'Updated Title',
            'description': 'Updated notes',
            'status': 'confirmed',
            'start': {'dateTime': existingEventTime.toUtc().toIso8601String()},
            'end': {'dateTime': existingEventTime.add(const Duration(hours: 1)).toUtc().toIso8601String()},
          }
        ]
      });

      when(() => mockHttpClient.send(any())).thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode(responseJson)),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      // Stub Apple plugin to return empty so it doesn't conflict
      final appleResult = Result<UnmodifiableListView<Event>>();
      appleResult.data = UnmodifiableListView<Event>([]);
      when(() => mockDeviceCalendarPlugin.hasPermissions()).thenAnswer((_) async => Result<bool>()..data = true);
      when(() => mockDeviceCalendarPlugin.retrieveEvents(any(), any())).thenAnswer((_) async => appleResult);

      // 2. Trigger sync
      await bookingProvider.syncExternalCalendars();
      await Future.delayed(const Duration(milliseconds: 100));

      // 3. Verify assertions
      final bookings = bookingProvider.bookings;

      // - New event should be added
      final added = bookings.firstWhere((b) => b.googleEventId == 'g_event_new');
      expect(added.title, equals('New Event Title'));
      expect(added.notes, equals('New notes'));

      // - Existing event should be updated
      final updated = bookings.firstWhere((b) => b.googleEventId == 'g_event_exist');
      expect(updated.title, equals('Updated Title'));
      expect(updated.notes, equals('Updated notes'));

      // - Missing event should be deleted
      final containsDeleted = bookings.any((b) => b.googleEventId == 'g_event_delete');
      expect(containsDeleted, isFalse);
    });

    test('syncExternalCalendars - Apple: Adds new event, updates existing, and deletes removed', () async {
      // 1. Stub Apple Calendar retrieveEvents returning 1 new event and 1 existing event
      final syncTime = DateTime(2026, 7, 29, 10, 0);
      final newEventTime = syncTime.add(const Duration(days: 2));
      final existingEventTime = syncTime.add(const Duration(days: 4));

      // Add existing booking to local Firestore
      final existingBooking = Booking(
        id: 'existing_booking_id',
        title: 'Old Apple Title',
        startTime: existingEventTime,
        endTime: existingEventTime.add(const Duration(hours: 1)),
        notes: 'Old notes',
        appleEventId: 'a_event_exist',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await dbService.addBooking(existingBooking);

      // Add another booking that will be DELETED because it's in sync range but missing from external events
      final deleteEventTime = syncTime.add(const Duration(days: 5));
      final deleteBooking = Booking(
        id: 'delete_booking_id',
        title: 'Delete Me',
        startTime: deleteEventTime,
        endTime: deleteEventTime.add(const Duration(hours: 1)),
        notes: '',
        appleEventId: 'a_event_delete',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await dbService.addBooking(deleteBooking);
      await Future.delayed(const Duration(milliseconds: 100));

      final appleResult = Result<UnmodifiableListView<Event>>();
      appleResult.data = UnmodifiableListView<Event>([
        Event(
          'apple_cal_123',
          eventId: 'a_event_new',
          title: 'New Apple Title',
          description: 'New notes',
          start: tz.TZDateTime.from(newEventTime, tz.local),
          end: tz.TZDateTime.from(newEventTime.add(const Duration(hours: 1)), tz.local),
        ),
        Event(
          'apple_cal_123',
          eventId: 'a_event_exist',
          title: 'Updated Apple Title',
          description: 'Updated notes',
          start: tz.TZDateTime.from(existingEventTime, tz.local),
          end: tz.TZDateTime.from(existingEventTime.add(const Duration(hours: 1)), tz.local),
        )
      ]);

      when(() => mockDeviceCalendarPlugin.hasPermissions()).thenAnswer((_) async => Result<bool>()..data = true);
      when(() => mockDeviceCalendarPlugin.retrieveEvents(any(), any())).thenAnswer((_) async => appleResult);

      // Disable Google Sync so it doesn't trigger
      await fakeDb
          .collection('users')
          .doc('user_123')
          .collection('configs')
          .doc('calendar_settings')
          .set({
        'google_sync_enabled': false,
        'apple_sync_enabled': true,
        'apple_calendar_id': 'apple_cal_123',
      });
      await Future.delayed(const Duration(milliseconds: 100));

      // 2. Trigger sync
      await bookingProvider.syncExternalCalendars();
      await Future.delayed(const Duration(milliseconds: 100));

      // 3. Verify assertions
      final bookings = bookingProvider.bookings;

      // - New event should be added
      final added = bookings.firstWhere((b) => b.appleEventId == 'a_event_new');
      expect(added.title, equals('New Apple Title'));
      expect(added.notes, equals('New notes'));

      // - Existing event should be updated
      final updated = bookings.firstWhere((b) => b.appleEventId == 'a_event_exist');
      expect(updated.title, equals('Updated Apple Title'));
      expect(updated.notes, equals('Updated notes'));

      // - Missing event should be deleted
      final containsDeleted = bookings.any((b) => b.appleEventId == 'a_event_delete');
      expect(containsDeleted, isFalse);
    });
  });
}
