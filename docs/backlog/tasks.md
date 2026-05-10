# Active Tasks: NMS Development (Phase 4)

## [Module] Core Infrastructure (COMPLETED)
- [x] Create directory structure @done(2026-04-27)
- [x] Setup Backlog Management System @done(2026-04-27)
- [x] Scaffold Flutter project @done(2026-04-27)
- [x] Configure Multi-Environment Firebase (Dev/Prod) @done(2026-05-03)

## [Module] Feature Implementation (COMPLETED)
- [x] Invoice Entry (Tab 1) @done(2026-04-28)
- [x] Dashboard & Reporting (Tab 2) @done(2026-04-29)
- [x] Expense Management @done(2026-05-03)
- [x] Photo Archival (Firestore/Storage) @done(2026-04-29)

## [Module] Phase 4: Multi-User & Security (COMPLETED)
- [x] Implement Anonymous Authentication @done(2026-05-04)
- [x] Stabilize Web Google Sign-In (Popups) @done(2026-05-04)
- [x] Implement User-Scoped Firestore Rules @done(2026-05-04)
- [x] Implement Manual Migration Logic v2.0.0 (JSON Export/Import) @done(2026-05-10)
- [x] Add Logout & Sign-In UI for Admin management @done(2026-05-10)
- [x] Ensure AppSettings (Bank/Services) preservation during migration @done(2026-05-10)
- [x] UAT Phase 4: Account Migration Verification @done(2026-05-10)

## [Module] Phase 5: Trial & Whitelist (PENDING)
- [/] Implement Trial Limits (20 Invoices)
- [x] Implement Admin Whitelist Bypass (Whitelisted for Migration Tools) @done(2026-05-10)

## [Module] Phase 6: Production Release Strategy (UPCOMING)
- [x] **Phase A: Master Backup** @done(2026-05-10)
    - [x] Run local app with `FLAVOR=prod`
    - [x] Export all legacy root data to `prod_master_backup.json`
- [x] **Phase B: Deployment** @done(2026-05-10)
    - [x] Final refactor: Remove debug logs and "(v2)" labels (Done for SettingsPage)
    - [x] Deploy UID-scoped code to Production Hosting
- [x] **Phase C: Transition** @done(2026-05-10)
    - [x] User onboarding to new UID/Auth flow
    - [x] Link Google accounts
- [x] **Phase D: Restoration** @done(2026-05-10)
    - [x] Distribute master JSON to users
    - [x] Execute "Restore" tool to recover legacy data

## [Module] Final Release Preparation
- [ ] App Store Screenshot generation
- [ ] Final production build and smoke test
