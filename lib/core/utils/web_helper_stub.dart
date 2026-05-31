
void downloadBackupWeb(String jsonString, String fileName) {
  throw UnsupportedError('downloadBackupWeb is only supported on web.');
}

void uploadBackupWeb({
  required void Function(Map<String, dynamic> jsonData) onSuccess,
  required void Function(Object error) onError,
}) {
  throw UnsupportedError('uploadBackupWeb is only supported on web.');
}

void downloadInvoiceImageWeb(List<int> pngBytes, String fileName) {
  throw UnsupportedError('downloadInvoiceImageWeb is only supported on web.');
}

void reloadPageWeb() {
  throw UnsupportedError('reloadPageWeb is only supported on web.');
}
