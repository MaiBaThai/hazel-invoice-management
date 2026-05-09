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

## 3. Legacy Data Migration Strategy

- **Detection**: Check for records in the old global collections on the first run of v1.5.0.
- **Automatic Migration**:
  - If legacy data is found AND the user is recognized (e.g., via Whitelist or a one-time "Claim Data" prompt), move records to the user's private collection.
  - Delete global records after successful verification to prevent duplication.

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
- **Paywall UI**: Show a modal when limits are reached, explaining the benefits of upgrading.
- **Whitelist (Admin Bypass)**:
  - Collection: `/system_configs/access_control`
  - Field: `whitelist_emails` (Array of emails).
  - If `user.email` is in the whitelist, set `isPremium = true` and bypass count checks.

## 6. Verification Plan
 
- [x] Verify anonymous login works on fresh install (Verified on Web).
- [x] Verify data isolation (Security Rules implemented).
- [ ] Verify legacy data migrates correctly to the new path.
- [ ] Verify "Limit Reached" dialog triggers at exactly 20 invoices.
- [ ] Verify whitelisted emails bypass the trial limits.
-
-## 7. Current Status (May 4, 2026)
-- **Auth Stabilization**: COMPLETED for Web using `signInWithPopup` and `linkWithPopup`.
-- **Data Migration**: Service implemented, pending Stage 2 UAT verification.
-- **Deployment**: v1.5.0-beta deployed to Firebase Hosting (dev environment).
