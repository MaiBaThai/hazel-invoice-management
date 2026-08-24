import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../core/providers/subscription_provider.dart';
import '../../core/providers/booking_provider.dart';
import '../subscription/paywall_bottom_sheet.dart';
import '../customers/customer_detail_page.dart';
import 'booking_dialog.dart';
import 'sync_settings_dialog.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static bool _hasShownSyncSettingsThisSession = false;

  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _syncChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkAndTriggerSync();
      }
    });
  }

  Future<void> _checkAndTriggerSync() async {
    if (_syncChecked) return;
    final bookingProvider = context.read<BookingProvider>();
    if (!bookingProvider.settingsLoaded) return;

    _syncChecked = true;
    bool permissionStateChanged = false;

    // Auto-request Apple calendar permission if sync is enabled on the account but not authorized on device
    if (bookingProvider.appleSyncEnabled) {
      final hasPerm = await bookingProvider.checkApplePermission();
      if (!hasPerm) {
        final granted = await bookingProvider.requestApplePermission();
        if (granted) {
          await bookingProvider.loadDeviceCalendars();
          permissionStateChanged = true;
        }
      }
    }

    if (!bookingProvider.hasSyncedThisSession || permissionStateChanged) {
      await bookingProvider.syncExternalCalendars();
    }
  }

  @override
  Widget build(BuildContext context) {
    final subProvider = context.watch<SubscriptionProvider>();
    final isPremium = subProvider.isPremium;

    if (!isPremium) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Calendar'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Calendar & Sync is Premium',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Manage your bookings, track customer appointments, and sync them seamlessly with Google and Apple Calendar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: () => PaywallBottomSheet.show(
                    context,
                    titleExplanation:
                        "Upgrade to Premium to unlock booking schedules and sync them with Google and iPhone Calendars!",
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('GO PREMIUM'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bookingProvider = context.watch<BookingProvider>();

    if (!bookingProvider.settingsLoaded) {
      _syncChecked = false;
    } else if (!_syncChecked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _checkAndTriggerSync();
        }
      });
    }

    if (isPremium && bookingProvider.settingsLoaded && !_hasShownSyncSettingsThisSession) {
      _hasShownSyncSettingsThisSession = true;
      if (!bookingProvider.googleSyncEnabled && !bookingProvider.appleSyncEnabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (mounted) {
            await showDialog(
              context: context,
              builder: (context) => const SyncSettingsDialog(),
            );
            if (mounted) {
              context.read<BookingProvider>().syncExternalCalendars();
            }
          }
        });
      }
    }

    final dayBookings = bookingProvider.bookings.where((b) {
      return isSameDay(b.startTime, _selectedDay);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) => const SyncSettingsDialog(),
              );
              if (context.mounted) {
                context.read<BookingProvider>().syncExternalCalendars();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // TableCalendar Widget wrapped in GestureDetector & AnimatedSize
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (_calendarFormat != CalendarFormat.month) {
                setState(() {
                  _calendarFormat = CalendarFormat.month;
                });
              }
            },
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: TableCalendar(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    // Auto-expand when selecting a day
                    _calendarFormat = CalendarFormat.month;
                  });
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                    // Auto-expand when swiping months
                    _calendarFormat = CalendarFormat.month;
                  });
                },
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  leftChevronIcon: Icon(Icons.chevron_left, color: Theme.of(context).colorScheme.primary),
                  rightChevronIcon:
                      Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
                ),
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                  ),
                  selectedTextStyle: const TextStyle(color: Colors.white),
                  todayTextStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                  markersMaxCount: 3,
                  markerDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                eventLoader: (day) {
                  return bookingProvider.bookings
                      .where((b) => isSameDay(b.startTime, day))
                      .toList();
                },
              ),
            ),
          ),
          const Divider(height: 1),
          // Day Bookings list wrapped in GestureDetector & NotificationListener
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  context.read<BookingProvider>().syncExternalCalendars(),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  if (_calendarFormat != CalendarFormat.week) {
                    setState(() {
                      _calendarFormat = CalendarFormat.week;
                    });
                  }
                },
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification notification) {
                    if (notification is ScrollStartNotification) {
                      if (_calendarFormat != CalendarFormat.week) {
                        setState(() {
                          _calendarFormat = CalendarFormat.week;
                        });
                      }
                    }
                    return false;
                  },
                  child: dayBookings.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: 200,
                              child: Center(
                                child: Text(
                                  'No bookings for ${DateFormat('dd MMMM yyyy').format(_selectedDay)}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: dayBookings.length,
                        itemBuilder: (context, index) {
                          final booking = dayBookings[index];
                          final timeStr =
                              '${DateFormat('HH:mm').format(booking.startTime)} - ${DateFormat('HH:mm').format(booking.endTime)}';
                          final duration = booking.endTime
                              .difference(booking.startTime)
                              .inMinutes;
                          final durationHrs = duration / 60.0;
                          final formattedHours = durationHrs
                              .toStringAsFixed(1)
                              .replaceAll(RegExp(r'\.0$'), '');

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      booking.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ),
                                  if (booking.customerId != null)
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CustomerDetailPage(
                                              customerId: booking.customerId!,
                                            ),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Theme.of(context).colorScheme.primary,
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(50, 30),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('View Client'),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time,
                                          size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$timeStr ($formattedHours hr${durationHrs == 1 ? '' : 's'})',
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  if (booking.notes.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.notes,
                                            size: 16, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            booking.notes,
                                            style: const TextStyle(
                                                color: Colors.grey),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => BookingDialog(
                                    booking: booking,
                                    initialDate: _selectedDay,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => BookingDialog(
              initialDate: _selectedDay,
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
