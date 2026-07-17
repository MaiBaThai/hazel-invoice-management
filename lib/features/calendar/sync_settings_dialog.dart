import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/booking_provider.dart';

class SyncSettingsDialog extends StatefulWidget {
  const SyncSettingsDialog({super.key});

  @override
  State<SyncSettingsDialog> createState() => _SyncSettingsDialogState();
}

class _SyncSettingsDialogState extends State<SyncSettingsDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final bookingProvider = context.watch<BookingProvider>();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Calendar Sync Settings'),
          SizedBox(height: 6),
          Text(
            'Automatically sync bookings to external calendars.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(color: Colors.pink),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Google Calendar Sync
                SwitchListTile(
                  title: const Text('Google Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
                  activeColor: Colors.pink,
                  value: bookingProvider.googleSyncEnabled,
                  onChanged: (val) async {
                    setState(() => _isLoading = true);
                    try {
                      final success = await bookingProvider.toggleGoogleSync(val);
                      if (!success && val && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to link Google Calendar scope.'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error linking Google Account: $e')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
                ),
                const Divider(),

                // iPhone Calendar Sync
                SwitchListTile(
                  title: const Text('iPhone Calendar', style: TextStyle(fontWeight: FontWeight.bold)),
                  activeColor: Colors.pink,
                  value: bookingProvider.appleSyncEnabled,
                  onChanged: (val) async {
                    setState(() => _isLoading = true);
                    try {
                      await bookingProvider.toggleAppleSync(val);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Permission error: $e')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
                ),

                // Apple Calendar Selector Dropdown
                if (bookingProvider.appleSyncEnabled &&
                    bookingProvider.deviceCalendars.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonFormField<String>(
                      value: bookingProvider.appleCalendarId,
                      decoration: const InputDecoration(
                        labelText: 'Select iPhone Calendar Target',
                        border: OutlineInputBorder(),
                      ),
                      items: bookingProvider.deviceCalendars.map((c) {
                        return DropdownMenuItem<String>(
                          value: c.id,
                          child: Text(c.name ?? 'Unnamed Calendar'),
                        );
                      }).toList(),
                      onChanged: (calId) {
                        if (calId != null) {
                          bookingProvider.toggleAppleSync(true, calendarId: calId);
                        }
                      },
                    ),
                  ),
                ] else if (bookingProvider.appleSyncEnabled) ...[
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'No writeable local calendars found. Ensure you granted local calendar access.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ),
                ],
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CLOSE', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}
