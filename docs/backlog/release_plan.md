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

### Phase 3: Settings & Data Management (v1.2.0) - [UPCOMING]
- **Objective**: Dynamic configuration and database management.
- **Key Features**:
  - Service List Management (Add/Edit/Delete).
  - Bank Account configuration (For VietQR).
  - Customer Data Management (Edit details, Delete customer with confirmation).

## Release Log

| Version | Date | Description | Status |
|---------|------|-------------|--------|
| v0.1.0-alpha | 2026-04-27 | Initial project scaffold & Phase 1 Core logic | Complete |
| v1.0.5 | 2026-04-27 | Official MVP Launch: PWA, VietQR, Save as Image | Released |
| v1.1.0 | 2026-04-28 | Phase 2: Dashboard, Revenue Charts, Customer History | Released |
| v1.1.1 | 2026-04-29 | Phase 3: Settings, Data Management, UX Polish, PWA logic | Released |
