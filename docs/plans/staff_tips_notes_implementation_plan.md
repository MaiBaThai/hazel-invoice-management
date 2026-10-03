# Kế Hoạch Triển Khai: Trang Quản Lý Staff, Cấu Trúc Bottom Nav, Tip & Commission & Notes Hóa Đơn

Tài liệu này tổng hợp toàn bộ các quyết định thiết kế đã thống nhất qua phiên **/grill-me**, mô hình dữ liệu (Schema Review) và kế hoạch triển khai chia theo từng giai đoạn (Phases / Issues).

---

## 1. Tổng Hợp Quyết Định Thiết Kế (Design Decisions)

| Hạng mục | Quyết định đã thống nhất |
| :--- | :--- |
| **Trang Staff riêng biệt** | Tách "Staff" thành trang riêng tương tự `CustomersPage`, hỗ trợ tìm kiếm, thêm, sửa, xóa, và trang chi tiết `StaffDetailPage`. |
| **Tái cấu trúc Bottom Nav** | Thay vị trí `Settings` trên thanh Bottom Navigation Bar bằng tab **`Staffs`** (Icon `badge` / `people_alt`). Giữ nguyên 6 tab: `Invoice`, `Expenses`, `Calendar`, `Dashboard`, `Customers`, `Staffs`. |
| **Vị trí Settings mới** | Chuyển icon Settings (`Icons.settings_outlined`) lên góc trên của **tất cả các tab chính** (AppBar actions/leading). Bấm vào sẽ mở `SettingsPage` dạng push screen với nút Back quay lại. |
| **Lưu trữ Staff trong Firestore** | Tạo collection riêng biệt: `users/{uid}/staff/{staffId}` để quản lý độc lập, hỗ trợ mở rộng, lưu lịch sử và thống kê doanh thu/tips. |
| **Mục Tip trên Invoice** | Nhập dạng số tiền (amount, vd: 30k, $5). Khách thanh toán `finalTotal = subtotal * (1 - discount%)`. Tip thanh toán mặt/riêng và được cộng trực tiếp vào thu nhập của Staff. |
| **Mục Commission trên Invoice** | Nhập dạng tỉ lệ `%` (vd: 10%). Hoa hồng = `(subtotal - discount) * commission%`. Khi chọn chip Staff, hệ thống tự động điền % hoa hồng mặc định của Staff đó. |
| **Chọn nhiều Staff** | Hỗ trợ chọn 1 hoặc nhiều Staff (Quick Chips). Tiền tip và hoa hồng được **chia đều** cho các Staff được chọn. |
| **Ghi chú trên Invoice (Notes)** | Input field multiline nhập ghi chú nội bộ cho hóa đơn. |
| **Hiển thị trên Biên lai gửi Khách** | **Chỉ hiện Staff** (vd: `Staff: Bảo, Ngọc`). **Ẩn hoàn toàn** Tip, Commission và Notes khỏi hình ảnh hóa đơn gửi khách hàng. |
| **Tab Notes trên Customer Details** | Bổ sung tab thứ 3 "Notes" trên `CustomerDetailPage` (Invoices \| Photos \| Notes) với đầy đủ CRUD (Thêm, Sửa, Xóa). Hiển thị song song ghi chú riêng của khách và ghi chú từ các Invoice cũ có badge `[Invoice #...]`. |
| **Customer Invoices List** | Hiển thị label/badge tên Staff bên cạnh số tiền Total bill trên mỗi dòng hóa đơn trong danh sách. |

---

## 2. Review Data Schema & Database Layer

### A. Model `Staff` (Mới)
Tạo file `lib/data/models/staff_model.dart`:
```dart
class Staff {
  final String id;
  final String name;
  final String phone;
  final double defaultCommissionPercent;
  final DateTime createdAt;
  final bool isActive;

  Staff({
    required this.id,
    required this.name,
    required this.phone,
    this.defaultCommissionPercent = 0.0,
    required this.createdAt,
    this.isActive = true,
  });

  factory Staff.fromMap(String id, Map<String, dynamic> map) {
    return Staff(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      defaultCommissionPercent: (map['default_commission_percent'] ?? 0.0).toDouble(),
      createdAt: map['created_at'] != null 
          ? (map['created_at'] as Timestamp).toDate() 
          : DateTime.now(),
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'name_lowercase': name.toLowerCase(),
    'phone': phone,
    'default_commission_percent': defaultCommissionPercent,
    'created_at': Timestamp.fromDate(createdAt),
    'is_active': isActive,
  };
}
```
* **Đường dẫn Firestore**: `users/{userId}/staff/{staffId}`.

### B. Model `Invoice` (Cập nhật)
Mở rộng các trường trong `lib/data/models/invoice_model.dart`:
```dart
class Invoice {
  // Các trường hiện hữu...
  final double tip;                  // Mặc định 0.0
  final double commissionPercent;    // Mặc định 0.0
  final List<String> staffNames;     // Danh sách tên staff phục vụ, mặc định []
  final String notes;                // Ghi chú nội bộ, mặc định ''
}
```
* **Tương thích ngược (Backward Compatibility)**:
  - Nếu hóa đơn cũ thiếu các trường này, fallback `tip = 0.0`, `commissionPercent = 0.0`, `staffNames = []`, `notes = ''`.
  - Không làm ảnh hưởng đến các dữ liệu hoặc test case hiện có.

### C. Model `CustomerNote` (Mới)
Tạo file `lib/data/models/customer_note_model.dart`:
```dart
class CustomerNote {
  final String id;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```
* **Đường dẫn Firestore**: `users/{userId}/customers/{customerId}/notes/{noteId}`.

---

## 3. Kế Hoạch Triển Khai Chia Theo Phase & Issues

### Phase 1: Data Models & Service Layer (Nền tảng Dữ Liệu)
- [x] **Task 1.1**: Tạo model `Staff` (`lib/data/models/staff_model.dart`).
- [x] **Task 1.2**: Cập nhật model `Invoice` (`lib/data/models/invoice_model.dart`) bổ sung `tip`, `commissionPercent`, `staffNames`, `notes`.
- [x] **Task 1.3**: Tạo model `CustomerNote` (`lib/data/models/customer_note_model.dart`).
- [x] **Task 1.4**: Cập nhật `DatabaseService` (`lib/data/services/database_service.dart`):
  - Collection reference: `_staffRef`.
  - CRUD Staff: `getStaffList()`, `addStaff()`, `updateStaff()`, `deleteStaff()`.
  - Truy vấn hóa đơn theo staff: `getStaffInvoices(String staffName)`.
  - CRUD Customer Notes: `getCustomerNotes()`, `addCustomerNote()`, `updateCustomerNote()`, `deleteCustomerNote()`.

### Phase 2: State Management (StaffProvider & InvoiceProvider)
- [x] **Task 2.1**: Tạo `StaffProvider` (`lib/core/providers/staff_provider.dart`):
  - Quản lý danh sách staff (`allStaff`, `activeStaff`, `searchResults`).
  - Tìm kiếm staff theo tên hoặc số điện thoại.
  - Quản lý thông tin chi tiết staff (`selectedStaff`, `staffInvoices`, thống kê tổng hoa hồng/tip).
- [x] **Task 2.2**: Đăng ký `StaffProvider` vào `MultiProvider` trong `lib/main.dart` với `ChangeNotifierProxyProvider<DatabaseService, StaffProvider>`.
- [x] **Task 2.3**: Cập nhật `InvoiceProvider` (`lib/core/providers/invoice_provider.dart`):
  - Bổ sung state: `selectedStaffNames` (danh sách staff được chọn), `tip`, `commissionPercent`, `notes`.
  - Cập nhật hàm tính toán hoa hồng: `staffCommissionAmount = (subtotal * (1 - discountPercent / 100)) * (commissionPercent / 100)`.
  - Cập nhật `saveInvoice`, `reset()`, và `loadInvoiceForEditing()`.

### Phase 3: Tái Cấu Trúc Navigation & Chuyển Vị Trí Settings
- [x] **Task 3.1**: Cập nhật `MainNavigationPage` (`lib/main.dart`):
  - Thay thế `SettingsPage()` ở index 5 bằng `StaffsPage()`.
  - Cập nhật danh sách 6 tab: `Invoice`, `Expenses`, `Calendar`, `Dashboard`, `Customers`, `Staffs`.
  - Cập nhật `CustomBottomNavBarItem` với icon `badge_outlined` / `badge` và nhãn `'Staffs'`.
- [x] **Task 3.2**: Thêm nút icon `Settings` (`Icons.settings_outlined`) lên AppBar của các trang chính:
  - `InvoicePage`, `ExpensesPage`, `CalendarPage`, `DashboardPage`, `CustomersPage`, `StaffsPage`.
  - Xử lý mở `SettingsPage` qua `Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()))`.

### Phase 4: Giao Diện Trang Quản Lý Staff & Chi Tiết Staff
- [x] **Task 4.1**: Xây dựng `StaffsPage` (`lib/features/staff/staffs_page.dart`):
  - Thanh tìm kiếm (Search bar) theo tên/số điện thoại.
  - Nút thêm mới nhân viên (Dialog thêm Tên, SĐT, % Hoa hồng mặc định).
  - Danh sách nhân viên hiển thị Tên, SĐT, % Hoa hồng mặc định, trạng thái.
  - Swipe hoặc popup menu để Sửa / Xóa / Tắt hoạt động.
- [x] **Task 4.2**: Xây dựng `StaffDetailPage` (`lib/features/staff/staff_detail_page.dart`):
  - Thẻ tóm tắt thông số: Tổng số hóa đơn đã làm, Tổng hoa hồng tích lũy, Tổng tiền tip nhận được.
  - Danh sách hóa đơn mà nhân viên này đã thực hiện.
  - Nút chỉnh sửa thông tin nhân viên hoặc xóa nhân viên.

### Phase 5: Cập Nhật Giao Diện & Trải Nghiệm Trang Invoice
- [x] **Task 5.1**: Khu vực dưới Customer:
  - Thêm tiêu đề "Staff" và hàng Quick Chips tải từ `StaffProvider.activeStaff`.
  - Hỗ trợ chọn/bỏ chọn nhiều chip.
  - Khi chọn staff đầu tiên, tự động gán `% commission` mặc định của staff đó vào ô Commission.
- [x] **Task 5.2**: Khu vực dưới Discount:
  - Thêm ô nhập **"Commission (%)"** (kèm hiển thị số tiền hoa hồng ước tính).
  - Thêm ô nhập **"Tip"** (số tiền tip nhận được).
- [x] **Task 5.3**: Khu vực Notes:
  - Thêm ô nhập ghi chú nhiều dòng (multiline TextField) trước khi bấm Summary.
- [x] **Task 5.4**: Invoice Summary Dialog:
  - Trên biên lai gửi khách: Chỉ hiển thị `Staff: Bảo, Ngọc`. Ẩn Tip, Commission và Notes.
  - Trên màn hình xác nhận nội bộ: Hiển thị đầy đủ Staff, Tip, Commission, Notes.

### Phase 6: Nâng Cấp Trang Khách Hàng (Customer Detail & Invoices List)
- [x] **Task 6.1**: Thêm tab **"Notes"** vào `CustomerDetailPage`:
  - Chuyển `TabController` từ 2 tabs sang 3 tabs: `Invoices`, `Photos`, `Notes`.
  - Nút thêm ghi chú nhanh.
  - Danh sách các ghi chú của khách hàng (có chức năng Edit & Delete).
  - Hiển thị liên kết các ghi chú từ lịch sử hóa đơn kèm badge `[Invoice - dd/MM/yyyy]`.
- [x] **Task 6.2**: Danh sách hóa đơn trong tab `Invoices`:
  - Thêm label/badge hiển thị tên Staff bên cạnh số tiền Total bill trên từng thẻ hóa đơn.

### Phase 7: Export CSV & Kiểm Thử Hóa Đơn Lịch Sử
- [x] **Task 7.1**: Cập nhật `CsvExportService` (`lib/core/services/csv_export_service.dart`):
  - Bổ sung các cột: `Staff`, `Tip`, `Commission %`, `Notes`.
- [x] **Task 7.2**: Cập nhật `InvoiceDetailView` (`lib/features/invoice/widgets/invoice_detail_view.dart`):
  - Hiển thị đầy đủ thông tin Staff, Tip, Commission và Notes khi chủ tiệm xem lại lịch sử hóa đơn.
- [x] **Task 7.3**: Chạy kiểm thử toàn bộ (`flutter test`) và xác minh các flow tạo hóa đơn, sửa hóa đơn, xem chi tiết khách hàng và staff.
