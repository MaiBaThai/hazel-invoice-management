# Release Plan: Nail Management System (NMS)

## Roadmap

### Phase 1: MVP & PWA (v1.0.5) - [COMPLETE]

- **Objective**: Core invoice entry, Firestore integration, and PWA deployment.
- **Key Features**:
  - [x] Customer selection/creation (Firestore).
  - [x] Service entry and automatic calculation.
  - [x] VietQR Payment Integration (Dynamic amount).
  - [x] "Save as Image" feature for invoices.
  - [x] PWA deployment to Firebase Hosting.
  - [x] Responsive layout (iPhone/iPad).

### Phase 2: Dashboard & Reports (v1.1.0) - [COMPLETE]

- **Objective**: Business insights and revenue tracking.
- **Key Features**:
  - [x] Dashboard with revenue stats (Today, This Month, This Year).
  - [x] Revenue bar chart (Last 7 days) using `fl_chart`.
  - [x] Advanced Customer history (Total spent, past invoices).
  - [x] Search invoices by customer name/phone.

### Phase 3: Settings & Data Management (v1.2.x) - [COMPLETE]

- **Objective**: Dynamic configuration and database management.
- **Key Features**:
  - [x] Service List Management (Add/Edit/Delete).
  - [x] Bank Account configuration (For VietQR).
  - [x] Customer Data Management (Edit details, Delete customer with confirmation).

### Phase 3.5: Expense & Photo Management (v1.4.x) - [COMPLETE]

- **Objective**: Expand to full financial tracking and visual archives.
- **Key Features**:
  - [x] **Photo Archival**: Capture and store work photos per invoice/customer.
  - [x] **Expense Tracking**: Itemized studio costs and categorization.
  - [x] **Advanced Dashboard**: Profit & Loss metrics (Revenue vs Expenses).
  - [x] **UX Polish**: Redesigned invoice detail and dual-view charts.

### Phase 4: Multi-User & Security (v1.5.0) - [COMPLETE]

- **Objective**: Implement secure user authentication and data isolation for App Store readiness.
- **Key Features**:
  - [x] **Guest Mode**: Implement Firebase Anonymous Auth to allow immediate usage without login.
  - [x] **Trial Management**: Enforcement logic for "20 Invoices / 10 Expenses" limitations.
  - [x] **Authentication**: Support for Google and Sign-in with Apple.
  - [x] **Account Linking**: Logic to "upgrade" anonymous data to a permanent account (Data Migration).
  - [x] **Whitelist Mechanism**: Firestore-based system to grant full access to specific UIDs/Emails (Admin/Tester bypass).
  - [x] **Firestore Data Scoping**: Migrate all data to `users/{uid}/...` structure with updated Security Rules.

### Phase 5: iOS Porting & Monetization (v2.0.0) - [PLANNING]

- **Objective**: Build, test, and integrate IAP for the native iOS application.
- **Key Features**:
  - [ ] **iOS UI Adaptation**: Smooth transitions, bottom navigation, and native-feeling dialogs.
  - [ ] **Monetization**: Integrate `in_app_purchase` package for iOS Subscriptions.
  - [ ] **Subscription Paywall**: UI to offer upgrade when trial limits are reached.
  - [ ] **App Store Compliance**: Register Bundle ID, Privacy Manifest, and metadata.
  - [ ] **TestFlight Distribution**: Internal and External testing phase.

## Release Log

| Version      | Date       | Description                                              | Status   |
| ------------ | ---------- | -------------------------------------------------------- | -------- |
| v0.1.0-alpha | 2026-04-27 | Initial project scaffold & Phase 1 Core logic            | Complete |
| v1.0.5       | 2026-04-27 | Official MVP Launch: PWA, VietQR, Save as Image          | Released |
| v1.1.0       | 2026-04-28 | Phase 2: Dashboard, Revenue Charts, Customer History     | Released |
| v1.1.1       | 2026-04-29 | Phase 3: Settings, Data Management, UX Polish, PWA logic | Released |
| v1.3.x       | 2026-04-30 | Phase 3.5: Firebase Storage, Photo Archival, CRM Polish  | Released |
| v1.4.1       | 2026-05-03 | Phase 3.5: Expense Management, P&L Dashboard, UX Polish  | Released |
| v1.5.0       | 2026-05-10 | Phase 4: Authentication, Guest Mode & Data Isolation     | Released |
| v1.5.2       | 2026-05-16 | Phase 4: Data Deletion & Session Management UX Polish    | Ready    |
| v2.0.0       | TBD        | iOS Release & App Store Submission (Major Version)       | Planning |
