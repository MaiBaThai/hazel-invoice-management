# Project Requirement: Nail Salon Management (Web-to-Mobile Version)

## 1. Project Overview

- **Project Name**: Nail Management System (NMS)
- **Primary Platform**: Flutter Web (PWA)
- **Secondary Platform**: iOS/iPadOS (Native build via Flutter)
- **Backend**: Firebase (Firestore & Hosting)
- **Goal**: Công cụ quản lý cá nhân không tốn phí (Zero-cost) để theo dõi doanh thu và lịch sử khách hàng.

## 2. Tech Stack

- **Frontend Framework**: Flutter (Cấu hình cho Web & Mobile)
- **Database**: Firebase Firestore (NoSQL)
- **Hosting**: Firebase Hosting (Để triển khai bản Web/PWA)
- **Cấu trúc**: Responsive design để hoạt động tốt trên cả iPhone và iPad.

## 3. Data Schema (Firestore)

### Collection: `customers`

- `id`: String (Auto-generated)
- `name`: String
- `phone`: String
- `total_spent`: Double
- `last_visit`: Timestamp

### Collection: `invoices`

- `id`: String
- `customer_id`: String (Reference)
- `customer_name`: String
- `services`: Array of Objects `[{ "service_name": String, "price": Double }]`
- `subtotal`: Double
- `discount_percent`: Double (default 0)
- `final_total`: Double
- `created_at`: Timestamp

## 4. Feature Specifications

### Tab 1: Ghi nhận hóa đơn (Invoice Entry)

- **Service Input**: Danh sách động để thêm/xóa dịch vụ vào hóa đơn (Ví dụ: "Sơn gel - 200k", "Đính đá - 50k").
- **Customer Selection**: Tìm kiếm khách hàng cũ hoặc thêm nhanh khách hàng mới.
- **Calculation Logic**:
  - `Subtotal = sum(service_prices)`
  - `FinalTotal = Subtotal * (1 - discount_percent/100)`
- **Action**: Lưu hóa đơn vào Firestore và tự động cộng dồn `total_spent` cho khách hàng đó đồng thời hiển thị sumary view đẹp mắt để gửi cho khách hàng (screenshot)

### Tab 2: Báo cáo & Tra cứu (Dashboard)

- **Revenue Stats**: Xem tổng doanh thu theo Ngày, Tháng, Năm.
- **Visuals**: Biểu đồ cột đơn giản cho doanh thu 7 ngày gần nhất.
- **History**: Thanh tìm kiếm theo Tên/SĐT khách hàng. Khi bấm vào một khách hàng, hiển thị danh sách tất cả hóa đơn cũ của họ (chronological history).

### Tab 3: Cấu hình & Tiện ích (Settings & Utilities)

- **Service List Management**: Cài đặt sẵn các dịch vụ làm nails thường xuyên (Ví dụ: Sơn gel, Đắp bột, Nối mi) kèm giá tiền.
  - Cho phép người dùng **Thêm mới**, **Chỉnh sửa** hoặc **Xóa** dịch vụ.
  - Thao tác này sẽ cập nhật trực tiếp vào lựa chọn hiển thị ở Tab 1.

## 5. PWA (Progressive Web App) Requirements

- Cấu hình `manifest.json` để chạy ở chế độ "standalone" (không thấy thanh địa chỉ trình duyệt).
- Cài đặt icon độ phân giải cao để hiển thị đẹp khi chọn "Add to Home Screen".
- Tự động tích hợp Firebase Core và Firestore Cloud.
- Thiết kế giao diện responsive để hiển thị tốt trên cả màn hình nhỏ (iPhone) và màn hình lớn (iPad).
- Sử dụng BottomNavigationBar để chuyển đổi giữa các tab

## 6. Future Migration Roadmap & Optimization

- **Platform-Agnostic Code**: Giữ logic xử lý (Business Logic) tách biệt hoàn toàn với Giao diện (UI). Hạn chế sử dụng các thư viện chỉ chạy được trên Web (web-only libraries) để đảm bảo quá trình chuyển đổi sang iOS mượt mà.
- **Responsive UI**: Sử dụng `LayoutBuilder` của Flutter để đảm bảo giao diện tự thích ứng từ iPhone sang iPad.
- **Firebase Configuration**: Chuẩn bị sẵn cấu hình để tích hợp thêm App ID của iOS vào cùng một Firebase Project trong tương lai.
