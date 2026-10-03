# Manual Test Checklist: Staff, Tips, Commission & Notes Feature

> **Version:** 1.0.4 (Build 59)  
> **Environment:** Production / TestFlight  
> **Target Platforms:** iOS / iPadOS / macOS / Web  
> **Status:** Ready for Verification (Post Commission & Notes Refinements)

---

## 📋 Mục Lục
1. [Chuẩn Bị Môi Trường Test](#1-chuẩn-bị-môi-trường-test)
2. [Checklist Phase 3: Điều Hướng (Navigation) & Cài Đặt (Settings)](#2-checklist-phase-3-điều-hướng-navigation--cài-đặt-settings)
3. [Checklist Phase 4: Quản Lý Nhân Viên (Staffs Page & Staff Detail)](#3-checklist-phase-4-quản-lý-nhân-viên-staffs-page--staff-detail)
4. [Checklist Phase 5: Tạo Hóa Đơn (Invoice Page, Tip, Commission, Notes)](#4-checklist-phase-5-tạo-hóa-đơn-invoice-page-tip-commission-notes)
5. [Checklist Phase 6: Trang Chi Tiết Khách Hàng (Customer Details & Notes Tab)](#5-checklist-phase-6-trang-chi-tiết-khách-hàng-customer-details--notes-tab)
6. [Checklist Phase 7: Xem Lịch Sử Hóa Đơn & Xuất File CSV](#6-checklist-phase-7-xem-lịch-sử-hóa-đơn--xuất-file-csv)
7. [Checklist Kiểm Thử Hồi Quy (Regression Testing)](#7-checklist-kiểm-thử-hồi-quy-regression-testing)
8. [Bảng Đánh Giá & Ký Duyệt (Sign-off)](#8-bảng-đánh-giá--ký-duyệt-sign-off)

---

## 1. Chuẩn Bị Môi Trường Test
- [ ] Cài đặt app bản build **1.0.4 (59)** qua TestFlight.
- [ ] Đăng nhập bằng tài khoản Google / Apple hoặc chế độ Anonymous.
- [ ] Đảm bảo thiết bị có kết nối mạng ổn định (kiểm tra Firestore đồng bộ).

---

## 2. Checklist Phase 3: Điều Hướng (Navigation) & Cài Đặt (Settings)

| ID | Kịch bản kiểm thử | Các bước thực hiện | Kết quả mong đợi | Trạng thái |
|---|---|---|---|:---:|
| **NAV-01** | Kiểm tra Bottom Navigation Bar | Mở app vào màn hình chính. Quan sát thanh điều hướng dưới cùng. | Thanh bottom bar hiển thị đủ 6 mục: `Invoice`, `Expenses`, `Calendar`, `Dashboard`, `Customers`, `Staffs` (icon thẻ tên badge). Tab `Settings` không còn ở thanh dưới. | [ ] |
| **NAV-02** | Chuyển đổi giữa các Tab | Lần lượt bấm vào từng tab trong Bottom Navigation Bar. | Chuyển trang mượt mà, tab được active đổi màu nổi bật, nội dung đúng từng màn hình. | [ ] |
| **NAV-03** | Icon Settings trên AppBar | Kiểm tra thanh AppBar trên các trang: `Invoice`, `Expenses`, `Calendar`, `Dashboard`, `Customers`, `Staffs`. | Mỗi trang đều có icon bánh răng `Settings` ở góc trên bên phải AppBar. | [ ] |
| **NAV-04** | Mở trang Settings từ AppBar | Bấm vào icon Settings ở bất kỳ trang nào. | Màn hình `SettingsPage` được mở lên dạng push view có nút Back quay về màn hình trước bình thường. | [ ] |

---

## 3. Checklist Phase 4: Quản Lý Nhân Viên (Staffs Page & Staff Detail)

| ID | Kịch bản kiểm thử | Các bước thực hiện | Kết quả mong đợi | Trạng thái |
|---|---|---|---|:---:|
| **STF-01** | Giao diện danh sách Staffs | Bấm vào tab `Staffs`. Quan sát danh sách, ô tìm kiếm và nút `+ Add Staff`. | Hiển thị danh sách nhân viên hiện có kèm SĐT, % hoa hồng mặc định và trạng thái (Active/Inactive). | [ ] |
| **STF-02** | Thêm mới nhân viên | Bấm nút `+ Add Staff` (hoặc Floating Action Button). Điền: Tên (bắt buộc), SĐT, % Commission mặc định (vd: 15%). Bấm Save. | Nhân viên mới lập tức xuất hiện trong danh sách, dữ liệu lưu lên Firestore thành công. | [ ] |
| **STF-03** | Tìm kiếm nhân viên | Gõ tên hoặc số điện thoại vào ô Search trên đầu trang Staffs. | Danh sách tự động lọc theo thời gian thực (real-time). Xóa từ khóa danh sách trở lại đầy đủ. | [ ] |
| **STF-04** | Chỉnh sửa thông tin nhân viên | Bấm icon ba chấm `...` (hoặc Edit) trên thẻ nhân viên. Sửa lại Tên, SĐT, % Commission hoặc Toggle Active/Inactive. Bấm Save. | Thẻ nhân viên cập nhật thông tin mới ngay lập tức. | [ ] |
| **STF-05** | Xóa nhân viên | Bấm Delete trên menu của nhân viên. Xác nhận xóa trên dialog cảnh báo. | Nhân viên biến mất khỏi danh sách. | [ ] |
| **STF-06** | Màn hình chi tiết nhân viên (`StaffDetailPage`) | Chạm vào một thẻ nhân viên để vào trang chi tiết. | Hiển thị: Avatar, Tên, SĐT, Trạng thái, và 3 thẻ tóm tắt số liệu: (1) Total Invoices, (2) Total Commission, (3) Total Tip, cùng tổng thu nhập ước tính. | [ ] |
| **STF-07** | Danh sách hóa đơn của nhân viên | Cuộn xuống phần "Invoices Served" trên trang Staff Detail. | Hiển thị các hóa đơn mà nhân viên này đã thực hiện, kèm số tiền hoa hồng + tip nhận được trên từng hóa đơn. | [ ] |

---

## 4. Checklist Phase 5: Tạo Hóa Đơn (Invoice Page, Tip, Commission, Notes)

| ID | Kịch bản kiểm thử | Các bước thực hiện | Kết quả mong đợi | Trạng thái |
|---|---|---|---|:---:|
| **INV-01** | Hiển thị Quick Chips Nhân Viên | Vào tab `Invoice`. Nhìn xuống khu vực dưới ô chọn Customer. | Hiển thị danh sách các nhân viên đang Active dưới dạng các Chip bấm chọn. | [ ] |
| **INV-02** | Chọn Nhân Viên & Auto-fill Commission | Bấm chọn 1 chip nhân viên (vd: Trang có commission mặc định là 15%). | Chip chuyển sang trạng thái đã chọn. Ô `% Commission` tự động điền `15` (hoặc % mặc định tương ứng của nhân viên). Bỏ chọn nhân viên thì commission reset về 0. | [ ] |
| **INV-03** | Chọn nhiều nhân viên (Multi-staff) | Bấm chọn tiếp nhân viên thứ 2 (vd: Ngọc). | Cả 2 chip đều được chọn. Tên cả 2 người sẽ được liên kết vào hóa đơn. | [ ] |
| **INV-04** | Nhập Tip | Nhập số tiền tip vào ô "Tip" dưới phần Discount (vd: 10$). | Ô hiển thị đúng số tiền tip, không gây lỗi định dạng số. | [ ] |
| **INV-05** | Nhập Commission & xem ước tính | Thay đổi số % trong ô Commission (vd: 15%). | Dòng chữ bên dưới hiển thị số tiền hoa hồng ước tính: `Est: $X.XX` được tính trên `(Subtotal - Discount) * %`. | [ ] |
| **INV-06** | Nhập Ghi chú hóa đơn (Notes) | Nhập ghi chú nhiều dòng vào ô "Invoice Notes" (vd: "Khách thích sơn bóng, lần sau làm French"). | Ô mở rộng mượt mà khi gõ xuống dòng, nhận đầy đủ nội dung. | [ ] |
| **INV-07** | Invoice Summary Dialog - Phiếu biên lai (Receipt) | Bấm nút "Summary" để mở popup xem trước biên lai. | Phần biên lai gửi cho khách: hiển thị dòng `STAFF: [Tên nhân viên]`. Đã gỡ bỏ toàn bộ khối "Internal Summary" (không còn hiển thị Tip, Commission %, Notes nội bộ trên dialog). | [ ] |
| **INV-08** | Chỉnh sửa Hóa Đơn (Edit Invoice) | Bấm "Edit Invoice" từ lịch sử hóa đơn. | Giao diện Invoice Page chuyển sang chế độ edit: Có banner nổi bật "Editing Invoice #...", nút bấm "REVIEW & UPDATE", hiển thị đầy đủ và chính xác tất cả thông tin đã lưu (Customer, Staff chips, Services, Discount, Tip, Commission %, Notes). | [ ] |
| **INV-09** | Lưu hóa đơn hoàn tất | Bấm nút "Save Invoice" (hoặc "REVIEW & UPDATE" khi sửa). | Hóa đơn lưu thành công, form hóa đơn được reset sạch sẽ (chip staff bỏ chọn, ô tip/commission/notes về trống). | [ ] |

---

## 5. Checklist Phase 6: Trang Chi Tiết Khách Hàng (Customer Details & Notes Tab)

| ID | Kịch bản kiểm thử | Các bước thực hiện | Kết quả mong đợi | Trạng thái |
|---|---|---|---|:---:|
| **CUS-01** | Cấu trúc 3 Tabs trong Customer Detail | Vào tab `Customers`, chọn 1 khách hàng đã có hóa đơn vừa tạo ở Phase 5. | Màn hình chi tiết hiển thị đủ 3 Tab: `Invoices`, `Photos`, `Notes`. | [ ] |
| **CUS-02** | Tab Invoices - Hiển thị Ngày, Giờ & Badge Staff | Chọn Tab `Invoices`. Quan sát danh sách các hóa đơn. | Hàng trên hiển thị ngày (`dd/MM/yyyy`), hàng dưới hiển thị khung giờ (`HH:mm - HH:mm` hoặc `HH:mm`) căn chỉnh thẳng hàng với Badge tên Staff (`Bảo, Ngọc`) và tổng tiền bên phải. | [ ] |
| **CUS-03** | Mở rộng chi tiết hóa đơn trong Tab Invoices | Chạm vào 1 hóa đơn để mở rộng (ExpansionTile). | Hiển thị đầy đủ: Services, Staff, Tip, Notes của hóa đơn đó. | [ ] |
| **CUS-04** | Tab Notes - Giao diện danh sách & Thêm ghi chú | Chuyển sang Tab `Notes`. Quan sát giao diện khi chưa có ghi chú và khi đã có ghi chú. | Đã bỏ ô quick-add ở đầu trang. Khi chưa có ghi chú: hiển thị câu gợi ý `"Enter notes for customer (e.g. skin sensitivity, preferences...)"`. Nút `"Add Note"` nằm ở cuối trang mở popup nhập ghi chú. | [ ] |
| **CUS-05** | Tab Notes - Chỉnh sửa & Xóa ghi chú | Bấm icon Edit để sửa ghi chú -> Bấm Update. Bấm icon Delete để xóa. | Ghi chú cập nhật nội dung đúng; xóa thành công khi xác nhận. | [ ] |
| **CUS-06** | Tab Notes - Liên kết ghi chú từ Hóa đơn | Kiểm tra danh sách trong Tab `Notes` của khách hàng vừa tạo hóa đơn có ghi chú ở Phase 5. | Xuất hiện thẻ ghi chú hóa đơn với Badge nổi bật: `[Invoice - DD/MM/YYYY]` kèm nội dung ghi chú đã nhập ở Phase 5. | [ ] |

---

## 6. Checklist Phase 7: Xem Lịch Sử Hóa Đơn & Xuất File CSV

| ID | Kịch bản kiểm thử | Các bước thực hiện | Kết quả mong đợi | Trạng thái |
|---|---|---|---|:---:|
| **HIS-01** | Xem chi tiết hóa đơn (`InvoiceDetailView`) | Vào tab `Dashboard` -> Bấm vào mục doanh thu ngày để mở `Daily Details` -> Chạm vào 1 hóa đơn. | Mở modal `InvoiceDetailView` hiển thị: Customer Name, Staff, danh sách Services, bảng phân tích Subtotal, Discount, Tip, Staff Commission, Total Amount, và khung "NOTES". | [ ] |
| **CSV-01** | Xuất file CSV hóa đơn | Vào `Settings` -> Bấm `Export Data to CSV` -> Chọn xuất `Invoices`. | Dialog chia sẻ hệ thống (Share Sheet) mở ra với file `invoices_YYYYMMDD_HHMMSS.csv`. | [ ] |
| **CSV-02** | Kiểm tra cấu trúc file CSV | Mở file CSV bằng Excel, Numbers hoặc Text Editor. | Cột tiêu đề chứa đủ: `Staff`, `Tip`, `Commission %`, `Notes`. Dòng dữ liệu hiển thị đúng tên Staff (phân cách bằng `;`), Tip (`10.00`), Commission (`15.0`), và nội dung Notes không bị vỡ cột khi có dấu phẩy/xuống dòng. | [ ] |

---

## 7. Checklist Kiểm Thử Hồi Quy (Regression Testing)

| ID | Khu vực | Kiểm tra | Kết quả mong đợi | Trạng thái |
|---|---|---|---|:---:|
| **REG-01** | Dashboard | Biểu đồ doanh thu & thống kê ngày/tuần/tháng | Hiển thị chính xác tổng doanh thu, tính toán không bị ảnh hưởng bởi hoa hồng hay tip. | [ ] |
| **REG-02** | Expenses | Thêm chi phí mới, xem danh sách | Hoạt động bình thường, không xung đột với các provider mới. | [ ] |
| **REG-03** | Calendar / Bookings | Tạo lịch hẹn mới, đồng bộ lịch Google/Apple | Tạo và hiển thị booking bình thường. | [ ] |
| **REG-04** | Offline & Sync | Tạo hóa đơn khi mất mạng, sau đó bật lại mạng | Dữ liệu lưu offline và tự động đồng bộ lên Cloud Firestore khi có mạng. | [ ] |

---

## 8. Bảng Đánh Giá & Ký Duyệt (Sign-off)

- **Người thực hiện test:** `........................................................`
- **Ngày hoàn thành test:** `....... / ....... / 2026`
- **Thiết bị kiểm thử:** `iPhone ............ / iOS version: ............`
- **Kết luận:**
  - [ ] **PASSED:** Tất cả các mục kiểm thử đạt yêu cầu. Sẵn sàng phát hành chính thức (Release to App Store).
  - [ ] **FAILED:** Có lỗi phát sinh cần điều chỉnh (ghi chú chi tiết lỗi bên dưới).

**Ghi chú lỗi phát sinh (nếu có):**
> ................................................................................................................................................
> ................................................................................................................................................
