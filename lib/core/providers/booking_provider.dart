import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:http/http.dart' as http;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/booking_model.dart';
import '../../data/services/database_service.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}

class BookingProvider extends ChangeNotifier {
  DatabaseService _dbService;
  final GoogleSignIn _googleSignIn;

  StreamSubscription? _bookingsSubscription;
  StreamSubscription? _settingsSubscription;

  List<Booking> _bookings = [];
  bool _isLoading = true;
  bool _googleSyncEnabled = false;
  bool _appleSyncEnabled = false;
  String? _appleCalendarId;
  List<Calendar> _deviceCalendars = [];

  final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();

  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  bool get googleSyncEnabled => _googleSyncEnabled;
  bool get appleSyncEnabled => _appleSyncEnabled;
  String? get appleCalendarId => _appleCalendarId;
  List<Calendar> get deviceCalendars => _deviceCalendars;

  BookingProvider(this._dbService, {GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn.instance {
    tz.initializeTimeZones();
    _startListeners();
  }

  void updateDbService(DatabaseService newService) {
    final oldUserId = _dbService.userId;
    _dbService = newService;
    if (oldUserId != newService.userId) {
      _startListeners();
    }
  }

  void _startListeners() {
    _bookingsSubscription?.cancel();
    _settingsSubscription?.cancel();

    _bookings = [];
    _isLoading = true;
    notifyListeners();

    if (_dbService.userId == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _bookingsSubscription = _dbService.watchBookings().listen(
      (list) {
        _bookings = list;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        debugPrint('Error listening to bookings: $err');
        _isLoading = false;
        notifyListeners();
      },
    );

    _settingsSubscription = _dbService.watchCalendarSettings().listen((snapshot) async {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        _googleSyncEnabled = data['google_sync_enabled'] ?? false;
        _appleSyncEnabled = data['apple_sync_enabled'] ?? false;
        _appleCalendarId = data['apple_calendar_id'];
      } else {
        _googleSyncEnabled = false;
        _appleSyncEnabled = false;
        _appleCalendarId = null;
      }
      if (_appleSyncEnabled) {
        await loadDeviceCalendars();
      }
      notifyListeners();
    });
  }

  Future<void> _saveSettings() async {
    if (_dbService.userId == null) return;
    await _dbService.updateCalendarSettings({
      'google_sync_enabled': _googleSyncEnabled,
      'apple_sync_enabled': _appleSyncEnabled,
      'apple_calendar_id': _appleCalendarId,
    });
  }

  // --- Device Calendar Permissions & Listing ---

  Future<bool> checkApplePermission() async {
    final permission = await _deviceCalendarPlugin.hasPermissions();
    return permission.isSuccess && permission.data == true;
  }

  Future<bool> requestApplePermission() async {
    final permission = await _deviceCalendarPlugin.requestPermissions();
    return permission.isSuccess && permission.data == true;
  }

  Future<void> loadDeviceCalendars() async {
    final permission = await checkApplePermission();
    if (!permission) return;

    final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    if (calendarsResult.isSuccess && calendarsResult.data != null) {
      _deviceCalendars = calendarsResult.data!.where((c) => c.isReadOnly == false).toList();
      notifyListeners();
    }
  }

  Future<void> toggleAppleSync(bool enabled, {String? calendarId}) async {
    if (enabled) {
      final granted = await requestApplePermission();
      if (!granted) return;
      await loadDeviceCalendars();
      _appleSyncEnabled = true;
      if (calendarId != null) {
        _appleCalendarId = calendarId;
      } else if (_deviceCalendars.isNotEmpty) {
        _appleCalendarId = _deviceCalendars.first.id;
      }
    } else {
      _appleSyncEnabled = false;
      _appleCalendarId = null;
    }
    await _saveSettings();
  }

  // --- Google Calendar Sync Enable ---

  Future<bool> toggleGoogleSync(bool enabled) async {
    if (enabled) {
      try {
        final client = _googleSignIn.authorizationClient;
        const calendarScope = 'https://www.googleapis.com/auth/calendar.events';
        final headers = await client.authorizationHeaders(
          [calendarScope],
          promptIfNecessary: true,
        );
        if (headers == null) return false;
        _googleSyncEnabled = true;
      } catch (e) {
        debugPrint('Error enabling Google Calendar sync: $e');
        return false;
      }
    } else {
      _googleSyncEnabled = false;
    }
    await _saveSettings();
    return true;
  }

  // --- Scheduling Conflict Detection ---

  List<Booking> getConflicts(DateTime start, DateTime end, {String? excludeId}) {
    return _bookings.where((b) =>
        b.id != excludeId &&
        start.isBefore(b.endTime) &&
        end.isAfter(b.startTime)
    ).toList();
  }

  // --- Booking CRUD & Sync Flow ---

  Future<void> createBooking(Booking booking) async {
    String? gEventId;
    String? aEventId;

    final tempBooking = booking.copyWith(
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // 1. Sync with Google Calendar
    if (_googleSyncEnabled) {
      gEventId = await _createGoogleEvent(tempBooking);
    }

    // 2. Sync with Apple Calendar
    if (_appleSyncEnabled && _appleCalendarId != null) {
      aEventId = await _createAppleEvent(tempBooking, _appleCalendarId!);
    }

    final finalBooking = tempBooking.copyWith(
      googleEventId: gEventId,
      appleEventId: aEventId,
    );

    await _dbService.addBooking(finalBooking);
  }

  Future<void> updateBooking(Booking booking) async {
    String? gEventId = booking.googleEventId;
    String? aEventId = booking.appleEventId;

    final updatedTimeBooking = booking.copyWith(updatedAt: DateTime.now());

    // 1. Google Sync
    if (_googleSyncEnabled) {
      if (gEventId != null) {
        await _updateGoogleEvent(gEventId, updatedTimeBooking);
      } else {
        gEventId = await _createGoogleEvent(updatedTimeBooking);
      }
    } else if (gEventId != null) {
      // Clean up Google Calendar if sync was toggled off
      await _deleteGoogleEvent(gEventId);
      gEventId = null;
    }

    // 2. Apple Sync
    if (_appleSyncEnabled && _appleCalendarId != null) {
      if (aEventId != null) {
        await _updateAppleEvent(aEventId, updatedTimeBooking, _appleCalendarId!);
      } else {
        aEventId = await _createAppleEvent(updatedTimeBooking, _appleCalendarId!);
      }
    } else if (aEventId != null) {
      // Clean up local iOS calendar if sync was toggled off
      if (_appleCalendarId != null) {
        await _deleteAppleEvent(aEventId, _appleCalendarId!);
      }
      aEventId = null;
    }

    final finalBooking = updatedTimeBooking.copyWith(
      googleEventId: gEventId,
      appleEventId: aEventId,
    );

    await _dbService.updateBooking(finalBooking);
  }

  Future<void> deleteBooking(Booking booking) async {
    // 1. Clean up Google Calendar Event
    if (booking.googleEventId != null && _googleSyncEnabled) {
      await _deleteGoogleEvent(booking.googleEventId!);
    }

    // 2. Clean up Apple Calendar Event
    if (booking.appleEventId != null && _appleSyncEnabled && _appleCalendarId != null) {
      await _deleteAppleEvent(booking.appleEventId!, _appleCalendarId!);
    }

    await _dbService.deleteBooking(booking.id);
  }

  // --- External Sync Private Helpers ---

  Future<String?> _createGoogleEvent(Booking booking) async {
    try {
      final client = _googleSignIn.authorizationClient;
      const calendarScope = 'https://www.googleapis.com/auth/calendar.events';
      final headers = await client.authorizationHeaders(
        [calendarScope],
        promptIfNecessary: false,
      );
      if (headers == null) return null;

      final httpClient = GoogleAuthClient(headers);
      final calendarApi = cal.CalendarApi(httpClient);

      final event = cal.Event(
        summary: booking.title,
        description: booking.notes,
        start: cal.EventDateTime(dateTime: booking.startTime.toUtc()),
        end: cal.EventDateTime(dateTime: booking.endTime.toUtc()),
      );

      final created = await calendarApi.events.insert(event, 'primary');
      httpClient.close();
      return created.id;
    } catch (e) {
      debugPrint('Google Calendar create event failed: $e');
      return null;
    }
  }

  Future<void> _updateGoogleEvent(String eventId, Booking booking) async {
    try {
      final client = _googleSignIn.authorizationClient;
      const calendarScope = 'https://www.googleapis.com/auth/calendar.events';
      final headers = await client.authorizationHeaders(
        [calendarScope],
        promptIfNecessary: false,
      );
      if (headers == null) return;

      final httpClient = GoogleAuthClient(headers);
      final calendarApi = cal.CalendarApi(httpClient);

      final event = cal.Event(
        summary: booking.title,
        description: booking.notes,
        start: cal.EventDateTime(dateTime: booking.startTime.toUtc()),
        end: cal.EventDateTime(dateTime: booking.endTime.toUtc()),
      );

      await calendarApi.events.patch(event, 'primary', eventId);
      httpClient.close();
    } catch (e) {
      debugPrint('Google Calendar update event failed: $e');
    }
  }

  Future<void> _deleteGoogleEvent(String eventId) async {
    try {
      final client = _googleSignIn.authorizationClient;
      const calendarScope = 'https://www.googleapis.com/auth/calendar.events';
      final headers = await client.authorizationHeaders(
        [calendarScope],
        promptIfNecessary: false,
      );
      if (headers == null) return;

      final httpClient = GoogleAuthClient(headers);
      final calendarApi = cal.CalendarApi(httpClient);

      await calendarApi.events.delete('primary', eventId);
      httpClient.close();
    } catch (e) {
      debugPrint('Google Calendar delete event failed: $e');
    }
  }

  Future<String?> _createAppleEvent(Booking booking, String calendarId) async {
    try {
      final hasPerm = await checkApplePermission();
      if (!hasPerm) return null;

      final location = tz.local;
      final event = Event(
        calendarId,
        title: booking.title,
        start: tz.TZDateTime.from(booking.startTime, location),
        end: tz.TZDateTime.from(booking.endTime, location),
        description: booking.notes,
      );

      final result = await _deviceCalendarPlugin.createOrUpdateEvent(event);
      if (result != null && result.isSuccess) {
        return result.data;
      }
      return null;
    } catch (e) {
      debugPrint('Apple Calendar create event failed: $e');
      return null;
    }
  }

  Future<void> _updateAppleEvent(String eventId, Booking booking, String calendarId) async {
    try {
      final hasPerm = await checkApplePermission();
      if (!hasPerm) return;

      final location = tz.local;
      final event = Event(
        calendarId,
        eventId: eventId,
        title: booking.title,
        start: tz.TZDateTime.from(booking.startTime, location),
        end: tz.TZDateTime.from(booking.endTime, location),
        description: booking.notes,
      );

      await _deviceCalendarPlugin.createOrUpdateEvent(event);
    } catch (e) {
      debugPrint('Apple Calendar update event failed: $e');
    }
  }

  Future<void> _deleteAppleEvent(String eventId, String calendarId) async {
    try {
      final hasPerm = await checkApplePermission();
      if (!hasPerm) return;

      await _deviceCalendarPlugin.deleteEvent(calendarId, eventId);
    } catch (e) {
      debugPrint('Apple Calendar delete event failed: $e');
    }
  }

  @override
  void dispose() {
    _bookingsSubscription?.cancel();
    _settingsSubscription?.cancel();
    super.dispose();
  }
}
