# Hướng dẫn Tối ưu hóa Tốc độ Kiểm thử & Tinh chỉnh UI/UX

Tài liệu này tổng hợp các phương pháp chạy và phát triển nhanh ứng dụng Flutter (NMS) cục bộ để tối ưu hóa tốc độ lập trình giao diện (UI/UX) và kiểm thử nhanh các tính năng mà không cần mất thời gian biên dịch lại toàn bộ app iOS hoặc đẩy qua TestFlight.

---

## Phương pháp 1: Chạy giả lập trên Trình duyệt Web (Chrome Mobile Emulator) — *NHANH NHẤT*

Đây là phương pháp tối ưu nhất để kiểm tra giao diện vì không cần biên dịch các thư viện Native phức tạp của iOS (như Firebase gRPC hay CocoaPods vốn mất 5-10 phút).

### Các bước thực hiện:

1. **Khởi chạy ứng dụng** trên môi trường Web Development bằng lệnh:
   ```bash
   flutter run -d chrome --flavor dev --dart-define=ENVIRONMENT=dev
   ```
   *Trình duyệt Chrome sẽ tự động mở lên sau vài giây.*

2. **Mô phỏng màn hình thiết bị di động (ví dụ iPhone X):**
   * Nhấn phím `F12` (hoặc tổ hợp phím `Cmd + Option + I` trên macOS) để mở **Chrome DevTools**.
   * Nhấp chọn biểu tượng **Device Toolbar** (hình điện thoại/máy tính bảng) ở góc trên bên trái của thanh DevTools (hoặc dùng phím tắt `Cmd + Shift + M`).
   * Ở thanh cấu hình kích thước thiết bị phía trên cùng, chọn các thiết bị mẫu như **iPhone X**, **iPhone 12/13/14 Pro** hoặc **iPad** để kiểm tra giao diện co giãn.

3. **Hot Reload thần tốc:**
   * Mỗi khi chỉnh sửa bất kỳ đoạn mã UI nào, chỉ cần nhấn **Save** (hoặc nhấn `r` ở cửa sổ terminal), giao diện trên trình duyệt sẽ được cập nhật **ngay lập tức (< 1 giây)** mà không làm mất trạng thái (state) hiện tại của màn hình.

---

## Phương pháp 2: Sử dụng tính năng "Hot Reload" trực tiếp trên iPhone thật

Bạn có thể cắm cáp và triển khai trực tiếp bản build **Debug (JIT)** lên thiết bị iPhone thật để kiểm thử thực tế cảm giác vuốt chạm và hiệu năng phần cứng.

### Các bước thực hiện:

1. **Kết nối thiết bị:**
   * Cắm iPhone vào máy Mac bằng cáp USB (hoặc đảm bảo cả hai thiết bị kết nối chung mạng Wi-Fi và đã bật chế độ Developer Mode trên iPhone).

2. **Lấy ID thiết bị:**
   * Chạy lệnh sau trong thư mục dự án để lấy tên hoặc ID thiết bị của bạn:
     ```bash
     flutter devices
     ```

3. **Khởi chạy ứng dụng lên iPhone thật:**
   * Thực thi lệnh build Debug lên điện thoại của bạn:
     ```bash
     flutter run -d <TÊN_HOẶC_ID_IPHONE_CỦA_BẠN> --flavor dev --dart-define=ENVIRONMENT=dev
     ```
     *Lưu ý: Lần chạy đầu tiên sẽ mất khoảng 2-3 phút để đồng bộ hóa mã nguồn ban đầu.*

4. **Hot Reload trên thiết bị thật:**
   * Sau khi ứng dụng đã hiển thị trên màn hình iPhone, bất kỳ thay đổi UI nào trong mã nguồn sẽ được cập nhật **ngay lập tức** khi bạn lưu file hoặc nhấn `r` tại terminal.

---

## Phương pháp 3: Chạy trực tiếp dưới dạng macOS Desktop App

Thích hợp khi bạn chỉ cần chạy thử để xem tổng thể bố cục widget nhanh gọn mà không cần mở giả lập hay trình duyệt.

### Các bước thực hiện:

1. **Chạy ứng dụng dưới dạng macOS Desktop:**
   ```bash
   flutter run -d macos --flavor dev --dart-define=ENVIRONMENT=dev
   ```
   *Ứng dụng sẽ được biên dịch và hiển thị dưới dạng một cửa sổ macOS sau vài giây.*

2. **Kiểm tra giao diện:**
   * Bạn có thể tự do co giãn hoặc thu hẹp chiều rộng cửa sổ ứng dụng về kích thước màn hình dọc của điện thoại để kiểm thử khả năng đáp ứng (responsiveness) của UI kết hợp với tính năng Hot Reload.
