import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';

/// Shows a platform-adapted popup to let the user select between camera or gallery.
///
/// On iOS, displays a [CupertinoActionSheet].
/// On other platforms (Android, Web, Desktop), displays a Material [ModalBottomSheet].
Future<ImageSource?> showImageSourceSheet(BuildContext context) {
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    return showCupertinoModalPopup<ImageSource>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Select Photo Source'),
        message: const Text('Capture a new photo or select from library'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.camera),
                SizedBox(width: 8),
                Text('Take Photo'),
              ],
            ),
            onPressed: () {
              Navigator.pop(context, ImageSource.camera);
            },
          ),
          CupertinoActionSheetAction(
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.photo_on_rectangle),
                SizedBox(width: 8),
                Text('Choose from Library'),
              ],
            ),
            onPressed: () {
              Navigator.pop(context, ImageSource.gallery);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  } else {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const ListTile(
              title: Text(
                'Select Photo Source',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.primary),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Theme.of(context).colorScheme.primary),
              title: const Text('Choose from Library'),
              onTap: () {
                Navigator.pop(context, ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
