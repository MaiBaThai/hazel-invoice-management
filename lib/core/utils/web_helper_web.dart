import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void downloadBackupWeb(String jsonString, String fileName) {
  final bytes = utf8.encode(jsonString);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

void uploadBackupWeb({
  required void Function(Map<String, dynamic> jsonData) onSuccess,
  required void Function(Object error) onError,
}) {
  final html.FileUploadInputElement input = html.FileUploadInputElement();
  input.accept = '.json';
  input.click();

  input.onChange.listen((event) {
    final files = input.files;
    if (files == null || files.isEmpty) return;

    final reader = html.FileReader();
    reader.readAsText(files[0]);
    reader.onLoadEnd.listen((e) {
      try {
        final String content = reader.result as String;
        final Map<String, dynamic> jsonData = jsonDecode(content);
        onSuccess(jsonData);
      } catch (err) {
        onError(err);
      }
    });
  });
}

void downloadInvoiceImageWeb(List<int> pngBytes, String fileName) {
  final blob = html.Blob([pngBytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}

void reloadPageWeb() {
  html.window.location.reload();
}
