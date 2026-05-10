# Production Release: Phase B - Deployment Plan

## Mục tiêu
Đưa toàn bộ mã nguồn đã được nâng cấp (hệ thống Auth, bảo mật UID, Migration Tools) lên môi trường Production (Hosting) chính thức.

## Trạng thái hiện tại
- [x] **Master Backup (Phase A):** Đã hoàn thành. File backup an toàn tại: `/Users/maibathai/Downloads/nms_root_backup_1778384165496.json`
- [x] **Database Admin Whitelist:** Đã cấu hình trên Production để đảm bảo sau khi deploy, admin vẫn có quyền truy cập bộ công cụ Migration.

## Các bước thực hiện

### 1. Build Production Bundle
Chúng ta cần đóng gói ứng dụng Flutter Web với cấu hình Production.
- **Command:** `flutter build web --release --dart-define=ENVIRONMENT=prod`
- **Lưu ý:** Việc sử dụng `--dart-define=ENVIRONMENT=prod` rất quan trọng để App trỏ đúng vào Firebase Production thay vì Dev.

### 2. Kiểm tra Firebase Target
Đảm bảo rằng lệnh deploy sẽ tác động vào đúng project `invoices-management-c4ef0` (Production).
- **Command:** `firebase use production` (hoặc alias tương ứng).

### 3. Triển khai (Deploy)
Đẩy toàn bộ folder `build/web` lên Firebase Hosting.
- **Command:** `firebase deploy --only hosting`

### 4. Kiểm tra sau triển khai (Smoke Test)
Truy cập vào URL chính thức của App và kiểm tra các điểm sau:
- [x] App hiển thị màn hình Login hoặc trạng thái Anonymous (không còn dữ liệu cũ ở root).
- [x] Có thể đăng nhập bằng Google Account (`thai.maiba1984@gmail.com`).
- [x] Sau khi đăng nhập, mục **Admin: Migration Tools** hiển thị chính xác.
- [x] Dữ liệu Invoices và Customers hiện tại phải là TRỐNG (vì chưa Restore).
- [x] **Restoration (Phase D):** Đã hoàn thành việc Restore dữ liệu từ JSON vào Target UID người dùng.

## Rủi ro & Cách xử lý
- **Rủi ro:** Người dùng mở app thấy dữ liệu trống sẽ hoảng loạn.
- **Xử lý:** Đây là trạng thái mong muốn trong quá trình chuyển đổi. Chúng ta sẽ thực hiện Phase D (Restoration) ngay lập tức sau khi xác nhận Phase B thành công.

---
**Người duyệt:** @maibathai
**Ngày lập:** 10/05/2026
