# Kế hoạch Tích hợp In Hoá đơn qua Bluetooth (Thermal Printer Integration)

Kế hoạch này chi tiết hoá việc cài đặt thư viện kết nối máy in nhiệt Bluetooth, cấu hình hệ thống (iOS/Android), viết Service/Provider quản lý máy in, tạo Widget in hoá đơn chuyên nghiệp hỗ trợ cả 58mm/80mm và tích hợp UI khoá tính năng chỉ dành cho tài khoản Premium.

---

## User Review Required

> [!IMPORTANT]
> **Rào cản iOS Bluetooth (BLE):**
> Do ứng dụng của bạn hướng tới iOS, thiết bị in hoá đơn của khách hàng **bắt buộc phải hỗ trợ BLE (Bluetooth Low Energy)** thì ứng dụng mới quét và kết nối được. Các máy in Bluetooth cũ chạy giao thức SPP (Classic) thông thường sẽ không hoạt động trên iOS. Cần khuyến nghị người dùng mua máy in nhiệt hỗ trợ BLE (ví dụ các dòng Xprinter Bluetooth/WiFi).

---

## Proposed Changes

### 1. Cấu hình Hệ thống & Thư viện

#### [MODIFY] [pubspec.yaml](file:///Users/maibathai/Documents/Personal/invoice/pubspec.yaml)
* Thêm hai thư viện chính:
  * `flutter_pos_printer_platform: ^1.0.8`: Quét và in qua Bluetooth BLE/Classic & LAN/WiFi.
  * `shared_preferences: ^2.2.0`: Lưu trữ cục bộ thông tin máy in mặc định đã kết nối và khổ giấy.

#### [MODIFY] [Info.plist](file:///Users/maibathai/Documents/Personal/invoice/ios/Runner/Info.plist)
* Thêm các khoá yêu cầu quyền sử dụng Bluetooth trên iOS để quét máy in BLE:
  ```xml
  <key>NSBluetoothAlwaysUsageDescription</key>
  <string>Ứng dụng cần quyền truy cập Bluetooth để tìm kiếm và kết nối với máy in nhiệt hoá đơn.</string>
  <key>NSBluetoothPeripheralUsageDescription</key>
  <string>Ứng dụng cần quyền truy cập Bluetooth để kết nối với máy in nhiệt hoá đơn.</string>
  ```

#### [MODIFY] [AndroidManifest.xml](file:///Users/maibathai/Documents/Personal/invoice/android/app/src/main/AndroidManifest.xml)
* Thêm các quyền Bluetooth cần thiết để tương thích với Android:
  ```xml
  <uses-permission android:name="android.permission.BLUETOOTH" />
  <uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
  <uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
  <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30" />
  ```

---

### 2. Lớp Core & State Management (Business Logic)

#### [NEW] [printer_provider.dart](file:///Users/maibathai/Documents/Personal/invoice/lib/core/providers/printer_provider.dart)
* Quản lý trạng thái quét (Scanning state), danh sách máy in tìm thấy (`List<PrinterDevice>`), trạng thái kết nối (`isConnected`), máy in đã chọn (`selectedDevice`), và kích thước khổ giấy (`paperWidth` - mặc định 58mm hoặc 80mm).
* Sử dụng `SharedPreferences` để tự động khôi phục máy in đã chọn ở lần chạy ứng dụng trước.
* Hàm `printReceiptImage(Uint8List imageBytes)`: Chuyển đổi mảng byte ảnh thành tập lệnh ESC/POS in ảnh và gửi đến máy in.

#### [MODIFY] [main.dart](file:///Users/maibathai/Documents/Personal/invoice/lib/main.dart)
* Khởi tạo `PrinterProvider` vào danh sách `MultiProvider` để cung cấp state kết nối máy in ở mọi màn hình (Invoices Page, Settings Page).

---

### 3. Giao diện & Tính năng (UI/UX)

#### [MODIFY] [settings_page.dart](file:///Users/maibathai/Documents/Personal/invoice/lib/features/settings/settings_page.dart)
* Thêm mục **Cài đặt máy in (Printer Settings)**:
  * **Nếu là Premium:** Cho phép quét máy in xung quanh, chọn thiết bị kết nối, chọn khổ giấy (58mm / 80mm) và in thử (Test print).
  * **Nếu là Free:** Hiển thị nút khoá Premium. Khi ấn vào sẽ mở `PaywallBottomSheet` để yêu cầu nâng cấp.

#### [NEW] [invoice_printer_widget.dart](file:///Users/maibathai/Documents/Personal/invoice/lib/features/invoice/widgets/invoice_printer_widget.dart)
* Tạo một Widget chuyên dụng để hiển thị hoá đơn dưới dạng đen trắng (được tối ưu hóa kích thước ngang 384px cho 58mm và 576px cho 80mm). Gồm tên tiệm, thông tin dịch vụ, tổng tiền, mã QR thanh toán (VietQR nếu dùng tiền Việt), lời cảm ơn.

#### [MODIFY] [invoice_page.dart](file:///Users/maibathai/Documents/Personal/invoice/lib/features/invoice/invoice_page.dart)
* Thêm một tuỳ chọn/nút **In Hoá Đơn** ở màn hình xem chi tiết hoá đơn.
* Kiểm tra `isPremium` khi người dùng ấn nút:
  * Nếu là Free: Chặn hiển thị và hiện `PaywallBottomSheet`.
  * Nếu là Premium: Mở Pop-up xem trước hóa đơn và nhấn nút "In" để chụp màn hình Widget `InvoicePrinterWidget` sang dạng ảnh và in qua `PrinterProvider`.

---

## Verification Plan

### Automated Tests
* Chạy build ứng dụng để đảm bảo dự án biên dịch thành công sau khi thêm thư viện mới:
  `flutter pub get` và `flutter build ios --simulator` hoặc `flutter test` (để kiểm tra xem có xung đột thư viện không).

### Manual Verification
* Khách hàng chạy app trên iOS/iPad thật để quét thử thiết bị Bluetooth.
* Chọn máy in, cấu hình khổ giấy, in hóa đơn thử nghiệm để kiểm tra độ sắc nét và font chữ tiếng Việt.
* Kiểm tra xem các tài khoản miễn phí (Free) có bị chặn và dẫn đến Paywall khi truy cập vào tính năng in hoặc cài đặt máy in hay không.
