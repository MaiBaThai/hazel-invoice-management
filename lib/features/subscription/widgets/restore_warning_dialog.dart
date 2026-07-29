import 'package:flutter/material.dart';

class RestoreWarningDialog extends StatelessWidget {
  const RestoreWarningDialog({super.key});

  /// Shows the restore warning dialog.
  /// Returns `true` if the user confirms restore, `false` otherwise.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Force explicit choice
      builder: (context) => const RestoreWarningDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orangeAccent,
            size: 28,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Restore Subscription?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: const Text(
        'This will transfer your App Store subscription to this account/session.\n\n'
        'Any other account currently using this subscription will lose Premium access.',
        style: TextStyle(height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'CANCEL',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: Colors.redAccent,
          ),
          child: const Text(
            'RESTORE',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
