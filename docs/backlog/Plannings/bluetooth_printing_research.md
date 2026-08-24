# Nghiên cứu Giải pháp In Hoá đơn qua Bluetooth (Flutter)

Tài liệu này tổng hợp các giải pháp kết nối Bluetooth và in hoá đơn nhiệt trong ứng dụng Flutter, giúp lựa chọn hướng đi tối ưu nhất về mặt trải nghiệm lập trình và độ ổn định của thiết bị.

---

## 1. Bản chất kỹ thuật & Rào cản lớn nhất
Khi làm việc với máy in nhiệt Bluetooth (ESC/POS), cần lưu ý hai điểm mấu chốt:
1. **Bluetooth Classic vs BLE (Bluetooth Low Energy):**
   * **Android:** Hỗ trợ cả Bluetooth Classic và BLE. Hầu hết máy in nhiệt giá rẻ trên thị trường đều dùng Bluetooth Classic.
   * **iOS (Apple):** Chỉ hỗ trợ **BLE** (hoặc Bluetooth Classic qua chuẩn MFi - rất đắt và hiếm ở máy in giá rẻ). Do đó, nếu ứng dụng chạy trên iOS, máy in bắt buộc phải hỗ trợ BLE hoặc in qua LAN/Wi-Fi.
2. **Định dạng dữ liệu gửi đi (ESC/POS Commands):**
   * Máy in nhiệt không hiểu PDF hay Text thuần thông thường. Chúng sử dụng tập lệnh điều khiển gọi là **ESC/POS** (do Epson phát triển). Bạn phải chuyển nội dung hoá đơn thành mảng byte ESC/POS rồi gửi qua cổng Bluetooth.

---

## 2. So sánh các Thư viện Flutter phổ biến nhất

| Thư viện | Loại kết nối hỗ trợ | Nền tảng | Ưu điểm | Nhược điểm |
| :--- | :--- | :--- | :--- | :--- |
| **`flutter_pos_printer_platform`**<br>*(Được khuyên dùng nhiều nhất)* | Bluetooth (Classic + BLE), Wi-Fi/LAN, USB | Android, iOS, Windows | • Đa năng, hỗ trợ nhiều cổng kết nối.<br>• API hiện đại, xử lý cả scan & connect và gửi dữ liệu.<br>• Tương thích tốt với các dòng máy POS cầm tay Sunmi. | • Setup cấu hình iOS phức tạp hơn (cần config BLE). |
| **`print_bluetooth_thermal`** | Bluetooth (Classic + BLE) | Android, iOS | • Thiết kế riêng cho in nhiệt.<br>• Rất dễ sử dụng, API tối giản.<br>• Có sẵn chức năng in text, in hình ảnh. | • Không hỗ trợ các kết nối khác ngoài Bluetooth (như USB/LAN). |
| **`blue_thermal_printer`** | Bluetooth Classic | Android | • Cực kỳ ổn định và phổ biến cho Android.<br>• Dễ dùng cho các máy in hóa đơn 58mm/80mm thông dụng. | • **Chỉ chạy trên Android** (không hỗ trợ iOS vì iOS không cho kết nối Bluetooth Classic tùy ý). |
| **`flutter_blue_plus`** + **`esc_pos_utils_plus`** | BLE (Bluetooth Low Energy) | Android, iOS | • Kiểm soát luồng kết nối Bluetooth cực sâu.<br>• Tránh được các lỗi từ wrapper plugins. | • Bạn tự viết code gửi byte chunk qua Bluetooth characteristic.<br>• Phức tạp hơn. |

---

## 3. Hai Phương pháp Thiết kế Layout Hoá đơn

### Hướng A: In dạng Text & Lệnh ESC/POS (Native Text Printing)
Sử dụng thư viện biên dịch như `esc_pos_utils_plus` để tạo chuỗi bytes:
```dart
// Ví dụ giả lập
bytes += generator.text('Nail Salon Invoice', styles: PosStyles(align: PosAlign.center, bold: true));
bytes += generator.hr();
bytes += generator.row([
  PosColumn(text: 'Dịch vụ A', width: 8),
  PosColumn(text: '200k', width: 4, align: PosAlign.right),
]);
```
* **Ưu điểm:**
  * Tốc độ in cực nhanh (gần như tức thì).
  * Tiết kiệm băng thông Bluetooth, chữ in ra sắc nét theo font mặc định của máy in.
* **Nhược điểm:**
  * **Hạn chế tiếng Việt có dấu:** Các máy in Trung Quốc giá rẻ thường không nạp font tiếng Việt (Unicode / CP1258). Chữ in ra sẽ bị lỗi font (ví dụ "Hoá đơn" thành "Ho'a ddon").
  * Khó thiết kế layout phức tạp, căn lề thủ công theo số cột (32 cột cho máy 58mm, 48 cột cho máy 80mm).

### Hướng B: Vẽ UI bằng Widget và Chuyển thành Ảnh (Widget-to-Image Printing)
Vẽ hoá đơn bằng Flutter Widget thông thường bên trong một `RepaintBoundary`, sau đó chụp ảnh Widget đó thành ảnh PNG/BMP dạng đơn sắc (monochrome) và gửi ảnh này tới máy in.
* **Ưu điểm:**
  * **Hỗ trợ 100% tiếng Việt có dấu**, font chữ tuỳ ý, logo đẹp mắt, icon sắc nét.
  * WYSIWYG (Thiết kế trên ứng dụng như thế nào, máy in ra đúng y như vậy).
  * Không lo lắng về vấn đề mã hoá ký tự của từng dòng máy in.
* **Nhược điểm:**
  * File ảnh có dung lượng lớn hơn nhiều so với text thô, dẫn đến tốc độ truyền tải Bluetooth chậm hơn (có thể mất 3 - 8 giây để truyền xong 1 tấm ảnh hóa đơn dài qua Bluetooth).
  * Nếu ảnh không được xử lý dither (đơn sắc hóa) tốt, chữ có thể hơi mờ hoặc răng cưa nhẹ.
