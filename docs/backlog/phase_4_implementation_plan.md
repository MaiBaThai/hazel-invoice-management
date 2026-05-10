# Phase 4 Implementation Plan: Multi-User & Security (v1.5.0)

## Overview

This document details the technical implementation of user authentication, data isolation, and trial management to prepare the NMS application for App Store submission.

## 1. Infrastructure & Authentication

- **Firebase Auth Setup**:
  - Enable **Anonymous**, **Google**, and **Apple** providers.
- **Silent Authentication**:
  - Implement `signInAnonymously()` on app startup if no user is present.
  - Ensures every user has a unique `uid` for data scoping immediately.
- **Account Management UI**:
  - Add a Profile/Settings section to display login status.
  - Implement "Link Account" functionality using `linkWithCredential` to merge guest data into permanent accounts (Google/Apple).

## 2. Data Scoping (Multi-Tenancy)

- **Path Migration**:
  - All Firestore references must shift from global paths to user-specific paths:
  - `/customers` -> `/users/{uid}/customers`
  - `/invoices` -> `/users/{uid}/invoices`
  - `/expenses` -> `/users/{uid}/expenses`
  - `/settings` -> `/users/{uid}/settings`
- **Repository Pattern Update**:
  - Update the Data Providers/Repositories to inject the current `uid` into every query and write operation.

## 3. Data Migration Strategy (Manual JSON Workflow)

- **Shift to Manual Process**: To ensure 1:1 data integrity and minimize risk during production cutover, we moved from an automatic background migration to a manual "Backup -> Verify -> Restore" workflow.
- **MigrationService (v2.0.0)**:
    - **Export**: Generates a standardized JSON file including search fields (`name_lowercase`), default values for missing fields, and full `AppSettings` (Bank config, Service menu).
    - **Import**: Performs a clean 1:1 restoration into the user's private collection (`/users/{uid}/...`).
- **User Flow**: Admin exports master data from Root -> Users login/link Google account -> Users upload JSON to restore their data.

## 4. Security Rules

- **Firestore Rules**:
  ```javascript
  match /users/{userId}/{document=**} {
    allow read, write: if request.auth != null && request.auth.uid == userId;
  }
  ```
- **Storage Rules**:
  ```javascript
  match /users/{userId}/{allPaths=**} {
    allow read, write: if request.auth != null && request.auth.uid == userId;
  }
  ```

## 5. Trial Enforcement & Whitelisting

- **Limitations**:
  - **Free Tier**: Max 20 invoices and 10 expenses.
  - **Logic**: Count documents in the user's sub-collections before allowing a "Save" action.
- **Whitelist (Admin Bypass)**:
  - Collection: `/system_configs/access_control`
  - Field: `whitelist_emails` (Array of emails).
  - If `user.email` is in the whitelist, the user is granted Admin/Premium status and can access Migration Tools.

## 6. Production Release Strategy (Go-Live Plan)

1. **Phase A: Master Backup**: [DONE] Run local dev environment pointing to Production (`FLAVOR=prod`) and export all root data to a master JSON.
2. **Phase B: Deployment**: [DONE] Deploy UID-scoped code to Production Hosting.
3. **Phase C: Transition**: [DONE] Existing users will start with a fresh Anonymous UID. They will link their Google accounts.
4. **Phase D: Restoration**: [DONE] Admin provides the master JSON to users; users use the "Restore" tool to recover their legacy data into their new private collections.

## 7. Verification Plan
 
- [x] Verify anonymous login works on fresh install.
- [x] Verify data isolation (Security Rules implemented).
- [x] Verify JSON Export/Import v2.0.0 (Integrity check passed).
- [x] Verify account linking and forced "Sign In" flow for Admin.
- [x] Verify `AppSettings` preservation during migration.

## 8. Current Status (May 10, 2026)
- **Status**: **COMPLETED & LIVE**.
- **Key Features**: Auth stabilization, Manual Migration Tools, Logout/Sign-in, Scoped Database logic.
- **Environment**: Production migrated successfully on May 10, 2026. Data restored to user-scoped collections.
