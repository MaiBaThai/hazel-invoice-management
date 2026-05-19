# Kế Hoạch Chuyển Đổi Kiến Trúc Multi-Tenant (Hybrid)

## 1. Tổng Quan Kiến Trúc (Hybrid Approach)
Kế hoạch này phác thảo giải pháp mở rộng ứng dụng quản lý hóa đơn hiện tại (cá nhân) thành một nền tảng hỗ trợ tổ chức (Studio/Doanh nghiệp nhỏ). Giải pháp sử dụng **mô hình Hybrid**, phân tách trải nghiệm người dùng dựa trên vai trò:
- **Mobile App (Ứng dụng hiện tại):** Tập trung vào việc nhập liệu nhanh (Tạo hóa đơn, Quản lý khách hàng). Dành cho người dùng cá nhân (Personal) và Nhân viên của Studio (Staff).
- **Web Dashboard (Ứng dụng mới):** Tập trung vào quản trị, báo cáo tổng hợp, xuất file dữ liệu phức tạp. Dành riêng cho Chủ Studio (Owner/Admin).
- **Shared Backend:** Dùng chung Firebase (Auth, Firestore, Storage) cho cả 2 ứng dụng.

---

## 2. Tái Cấu Trúc Cơ Sở Dữ Liệu (Firestore Refactoring)
Để hỗ trợ Multi-tenant, cấu trúc dữ liệu cần chuyển từ **User-centric** sang **Tenant-centric (Studio)**. Mọi người dùng cá nhân mặc định sẽ được coi là một "Studio" có 1 thành viên duy nhất.

### 2.1 Cấu Trúc Firestore Mới Đề Xuất
```javascript
// 1. Tổ chức / Studio
/studios/{studioId}
    - name: string
    - ownerId: string
    - createdAt: timestamp
    - settings: map (chứa config về thuế, logo, v.v.)

// 2. Thành viên trong Studio
/studios/{studioId}/members/{userId}
    - role: string ("owner" | "manager" | "staff")
    - joinedAt: timestamp
    - status: string ("active" | "invited")

// 3. Khách hàng (Sở hữu bởi Studio)
/studios/{studioId}/customers/{customerId}
    - name, phone, address...
    - createdBy: {userId}
    - createdAt: timestamp

// 4. Hóa đơn (Sở hữu bởi Studio)
/studios/{studioId}/invoices/{invoiceId}
    - total, items, status...
    - customerId: {customerId}
    - createdBy: {userId}
    - createdAt: timestamp
```

### 2.2 Chiến Lược Migration Dữ Liệu Cũ
Dữ liệu hiện tại đang nằm ở `/users/{userId}/...` cần được migrate bằng một Cloud Function chạy 1 lần (One-off script):
1. Tạo một `studio` mới cho mỗi `user` hiện tại. Gán `ownerId = userId`.
2. Copy toàn bộ collection `invoices` và `customers` từ `/users/{userId}/` sang `/studios/{studioId}/`.
3. Cập nhật app để trỏ đường dẫn đọc/ghi data sang cấu trúc mới.

---

## 3. Cập Nhật Firebase Security Rules (RBAC)
Security rules phải được viết lại để kiểm tra quyền truy cập dựa trên file `members`.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
  
    // Function kiểm tra quyền trong studio
    function getRole(studioId) {
      return get(/databases/$(database)/documents/studios/$(studioId)/members/$(request.auth.uid)).data.role;
    }
    function isStaffOrOwner(studioId) {
      return getRole(studioId) in ['staff', 'manager', 'owner'];
    }
    function isOwner(studioId) {
      return getRole(studioId) == 'owner';
    }

    match /studios/{studioId} {
      allow read: if isStaffOrOwner(studioId);
      allow write: if isOwner(studioId);
      
      match /invoices/{invoiceId} {
        allow read, create: if isStaffOrOwner(studioId);
        // Có thể cấu hình nhân viên chỉ được sửa hóa đơn của mình, owner được sửa tất cả
        allow update, delete: if isOwner(studioId) || request.resource.data.createdBy == request.auth.uid; 
      }
    }
  }
}
```

---

## 4. Kế Hoạch Nâng Cấp Mobile App (Flutter)
App Mobile hiện tại cần được cập nhật để hỗ trợ "Context Switching" (Chuyển đổi không gian làm việc).

### 4.1 UI / UX Changes
- **Workspace Switcher:** Thêm một Dropdown ở góc trên màn hình (hoặc trong Drawer) để user chọn "Không gian cá nhân" hoặc "Tên Studio A", "Tên Studio B".
- **Join Studio Flow:** Màn hình nhập mã Invite Code để tham gia vào một Studio.

### 4.2 State Management (Providers)
- Tạo thêm `WorkspaceProvider` để lưu trữ `currentStudioId` đang được chọn.
- Refactor `InvoiceProvider`, `CustomerProvider` và `DatabaseService`: Thay vì inject `userId`, bây giờ sẽ inject `currentStudioId` vào các truy vấn Firestore.
  - Ví dụ: `db.collection('studios').doc(currentStudioId).collection('invoices')`.

---

## 5. Phát Triển Web Dashboard (Admin App)
Đây là ứng dụng riêng biệt giúp Owner quản lý hiệu quả hơn. (Có thể dùng Flutter Web hoặc Next.js).

### Tính năng MVP:
- **Xác thực:** Đăng nhập cùng tài khoản Firebase Auth của Mobile.
- **Quản trị Nhân sự:** Xem danh sách nhân viên, thêm mới (tạo Invite Code), xóa nhân viên, phân quyền.
- **Báo cáo (Analytics):** Biểu đồ doanh thu theo tháng/tuần, lọc theo từng nhân viên (Ai tạo ra nhiều hóa đơn nhất).
- **Export/Import:** Xuất toàn bộ dữ liệu hóa đơn ra Excel/CSV. In hóa đơn hàng loạt.
- **Cấu hình Studio:** Tải lên Logo công ty chung, tùy chỉnh mẫu hóa đơn.

---

## 6. Lộ Trình Triển Khai (Roadmap)

### Phase 1: Database Foundation (Core Refactoring)
- Thiết kế lại Firestore Security Rules.
- Viết script migration (Node.js/Cloud Functions) để migrate dữ liệu của user hiện tại sang dạng Studio.
- Cập nhật `DatabaseService` trong Mobile app để đọc/ghi vào `studios/{studioId}`.
*(Ở Phase này UI không thay đổi, người dùng không nhận ra sự khác biệt, nhưng core đã sẵn sàng cho multi-tenant).*

### Phase 2: Mobile Workspace Context
- Xây dựng UI `Workspace Switcher` trên Mobile app.
- Xây dựng luồng "Join Studio" bằng mã code trên Mobile app.
- Thử nghiệm việc 2 user truy cập chung 1 dữ liệu Studio.

### Phase 3: Web Dashboard MVP (Cho Owner)
- Setup project Web.
- Tích hợp Đăng nhập, Hiển thị Dashboard cơ bản.
- Chức năng Quản lý nhân viên (Tạo mã mời).
- Phát hành bản Beta cho một vài Owner dùng thử.

### Phase 4: Nâng cao & Tối ưu
- Thêm Cloud Functions để tự động tổng hợp doanh thu (aggregation) giảm số lần đọc (reads) trên Firestore.
- Thêm push notifications báo cho Owner khi nhân viên tạo hóa đơn mới có giá trị lớn.
- Báo cáo và Export Excel chi tiết.
