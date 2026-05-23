# Product Backlog: Nail Management System (NMS)

This document outlines the features and user stories for the NMS, prioritized for development.

## Epic 1: Invoice Management (Core MVP)
*Goal: Allow users to record services and generate invoices efficiently.*

- [x] **STORY-001**: As a user, I want to search for existing customers or add new ones during invoice entry.
- [x] **STORY-002**: As a user, I want to add multiple services to an invoice with dynamic price calculation.
- [x] **STORY-003**: As a user, I want to apply a discount percentage to the total invoice amount.
- [x] **STORY-004**: As a user, I want to save invoices to Firestore and have the customer's `total_spent` updated automatically.
- [x] **STORY-005**: As a user, I want to see a beautiful summary view of the invoice with a payment QR code and an option to save as image.
- [x] **STORY-027**: As a user, I want to view, download, and edit past invoices directly from the customer's history, with automatic `total_spent` adjustments.
- [x] **STORY-035**: As a user, I want to input the session date & times (check-in/check-out style) for invoices to precisely track service duration and feed scheduling analytics.

## Epic 2: Reporting & Dashboard
*Goal: Provide insights into business performance.*

- [x] **STORY-006**: As a user, I want to see total revenue stats by Day, Month, and Year.
- [x] **STORY-007**: As a user, I want a visual bar chart showing revenue for the last 7 days (Upgraded/Expanded to trailing 14D/30D/90D/YTD charts).
- [x] **STORY-008**: As a user, I want to search customer history by Name or Phone number.
- [x] **STORY-009**: As a user, I want to view a chronological list of all past invoices for a specific customer.
- [x] **STORY-031**: As a user, I want to filter my dashboard by different date ranges (14 Days daily, 30 Days weekly, 90 Days weekly, YTD monthly).
- [x] **STORY-032**: As a user, I want to see dynamic summary cards on my dashboard, including Revenue, Expenses, Net Profit with Margin percentage, and Average Ticket Value (ATV).
- [x] **STORY-033**: As a user, I want to see a ranking podium column chart of my top 3 services to identify high-performing services at a glance.
- [x] **STORY-034**: As a user, I want to see a weekday vs time-slot heat map showing my busiest times to optimize schedule/staffing.

## Epic 3: Configuration & Settings [DONE]
- [x] Story 1: As a user, I want to edit/delete customer information to maintain a clean database.
- [x] Story 2: As a user, I want to configure my bank account for VietQR generation dynamically.
- [x] Story 3: As a user, I want to manage a predefined list of services (Service Menu) for quick entry.
- [x] Story 4: As a user, I want quick-add chips in the invoice tab to speed up entry.
- [x] **STORY-028**: As a user, I want to permanently delete all my data while remaining logged in, ensuring my privacy and allowing me to start fresh.
- [x] **STORY-029**: As a user, I want to configure my business name and currency options (k or $) to localize the app branding and pricing.
- [x] **STORY-030**: As a user, I want to receive a confirmation warning when changing currency settings, explaining that historical invoices are not mathematically converted.


## Epic 4: PWA & Platform Optimization
*Goal: Ensure high-quality experience across devices.*

- [x] **STORY-012**: As a user, I want to install the app as a PWA on my iPhone/iPad home screen.
- [x] **STORY-013**: As a user, I want a responsive layout that adapts perfectly between iPhone and iPad screen sizes.
- [x] **STORY-014**: As a user, I want smooth navigation between features using a bottom navigation bar.

## Epic 5: Photo Archival & CRM Polish [NEW]
*Goal: Integrate visual records and advanced CRM management.*

- [x] **STORY-015**: As a user, I want to take/upload photos for each invoice to archive work results.
- [x] **STORY-016**: As a user, I want a centralized photo library for each customer.
- [x] **STORY-017**: As a user, I want to delete photos from both the invoice and the gallery view.
- [x] **STORY-018**: As a user, I want to edit customer names and phone numbers to keep records accurate.

## Epic 6: Expense Management & Financial Tracking [NEW]
*Goal: Track operating costs to calculate studio profitability.*

- [x] **STORY-020**: As a user, I want to record expenses with itemized descriptions and costs.
- [x] **STORY-021**: As a user, I want quick-add categories (Rent, Supplies, Utilities) to speed up expense entry.
- [x] **STORY-022**: As a user, I want to see the impact of expenses on my daily/monthly profit on the Dashboard.

## Epic 7: Multi-User & Security [DONE]
*Goal: Implement secure user authentication and data isolation.*

- [x] **STORY-023**: As a user, I want to use the app immediately as a guest without creating an account.
- [x] **STORY-024**: As a user, I want to sign in with my Google account to save my data permanently.
- [x] **STORY-025**: As a user, I want my data to be securely isolated from other users.
- [x] **STORY-026**: As an admin, I want to backup and restore legacy data to specific user accounts.

## Changelogs - May 23, 2026
### v1.8.0 - Client Session Time Tracking & Heatmap Optimization (2026-05-23)
- **Check-in/Check-out Session Picker**: Implemented a fast session date & time range picker (30-minute blocks, 07:00 to 24:00) with a compact date slider row (left/right chevron navigation and direct calendar picker).
- **Mandatory Session Validation**: Enforced session timing input for new invoices, displaying warning indicators ("Mandatory field - tap to select") dynamically upon checkout pre-view/save attempt.
- **Enhanced Time Displays**:
  - **Invoice Detail**: Under customer name, displays as `dd/MM/yyyy  HH:mm - HH:mm (duration hrs)`.
  - **Daily Details Dialog**: Displays starting time of invoice under customer name.
  - **Customer History**: Displays session times and duration for past invoice items.
- **Precision Heatmap Analytics**: Updated the "Busiest Days & Times" dashboard heatmap to aggregate counts based on actual session start times (`sessionStart` with fallback to `createdAt`), maintaining `createdAt` for financial analytics.
- **Compact Dashboard & Tabbed Analytics**: Redesigned overview metrics cards to use side-by-side title/subtitle layouts with a tight grid aspect ratio (2.3). Added a Segmented Chart View Selector (switching between Performance, Top Services, and Busiest Times) to fit the entire dashboard screen on mobile devices without scrolling.

## Changelogs - May 22, 2026
### v1.7.0 - Advanced Salon Dashboard & Date Range Analytics (2026-05-22)
- **Flexible Date Filtering**: Introduced a sliding segment selector for multiple date ranges (14 Days daily, 30 Days weekly, 90 Days weekly, YTD monthly) with 365 days of historical data fetching.
- **Dynamic KPI Summary Grid**: Replaced static cards with a 2x2 grid displaying Revenue, Expenses, Net Profit with Margin percentage, and Average Ticket Value (ATV).
- **Interactive Grouped Charting**: Updated the main bar chart to dynamically adjust bar groupings, formatting, and click-drilldown details based on the selected date range.
- **Top 3 Services Podium**: Added a compact, Row-based vertical bar ranking podium (`[2nd, 1st, 3rd]`) showing revenue shares and visit counts for high-performing services.
- **Busiest Days & Times Heat Map**: Integrated a 7x5 interactive heat map (weekdays vs time slots) with density shading and click/tap tooltips showing exact visit counts.

## Changelogs - May 19, 2026
### v1.6.1 - Optional VietQR Prefill Amount (2026-05-19)
- **VietQR Transfer Amount**: Removed the prefilled transaction amount from generated VietQR codes on invoices, allowing customers to manually enter the amount in their banking apps (addressing restrictions in certain bank apps).

### v1.6.0 - Business Profile & Global Currency Localization (2026-05-19)
- **Business Profile**: Added a "Business Profile" configuration card to modify the business name and currency options.
- **Branding & Localization**: Replaced hardcoded "Hazel Nails" default text and currency symbols ("k" VND) with dynamic variables dynamically fetched from `app_settings` via `SettingsProvider`.
- **Conditional VietQR**: Dynamically disables the VietQR settings card and invoice QR code rendering when switching to foreign currencies like `$ (USD)`.
- **Currency Settings Confirmation**: Implemented a warning pop-up dialog when changing currency settings to prevent unintended side effects on past invoices.

## Changelogs - May 16, 2026
### v1.5.2 - Data Deletion & UX Polish (2026-05-16)
- **Data Privacy**: Implemented a secure "Danger Zone" allowing users to permanently delete all their data (Firestore & Storage) while generating an automatic backup.
- **Session Management**: Optimized the deletion flow to keep users logged in, seamlessly resetting the app state to a clean slate without requiring re-authentication.

## Changelogs - May 13, 2026
### v1.5.1 - Invoice Editing & History Polish (2026-05-13)
- **Edit History**: Added the ability to open, view, edit, and re-download historical invoices directly from the Customer Detail page.
- **Data Integrity**: Implemented transactional logic to recalculate and update a customer's `total_spent` automatically when an old invoice is edited.

## Changelogs - May 10, 2026
### v1.5.0 - Multi-User, Security & Migration (2026-05-10)
- **Official Release**: Transitioned from beta to official release.
- **Migration**: Manual JSON workflow for data migration from global to user-scoped collections.
- **Production Deployment**: Scoped database logic and security rules deployed to production.

## Changelogs - May 4, 2026
### v1.5.0-beta - Auth Stabilization & Security (2026-05-04)
- **Auth Stabilization**: Fixed `UnimplementedError` on Web by implementing native `signInWithPopup` and `linkWithPopup`.
- **Data Scoping**: Fully implemented Firestore Security Rules to isolate user data.
- **Migration Service**: Added logic to migrate legacy/anonymous data to permanent Google accounts.
- **Environment Alignment**: Standardized project initialization for consistent behavior across Dev/Prod and Web/Mobile.

## Changelogs - May 3, 2026
### v1.4.1 - Expense Management & Dashboard UI (2026-05-03)
- **New Feature**: Full Expense Management system with itemized cost tracking.
- **Dashboard Upgrade**: Integrated Profit & Loss metrics (Revenue vs Expenses).
- **UI Enhancement**: Dual-data performance chart (last 7 days).
- **UX Improvement**: New "Daily Performance" dialog with tabs for Revenue and Expenses.
- **UX Improvement**: Redesigned Invoice Detail view with drag handle and close button for better mobile accessibility.
- **Photo Integration**: Integrated photo thumbnails into the daily invoice detail with full-screen viewing support.
- **Rendering Fixes**: Switched to `Wrap` layout for photos and added loading/error handling to stabilize web rendering.
- **CORS Management**: Configured production Storage CORS to ensure cross-origin image loading works correctly.

### v1.3.9
- **Expense Management**: Introduced a new Expenses tab for tracking studio costs.
- **Categorization**: Added quick-add chips for Rent, Supplies, and Utilities (Electricity, Water, Internet).
- **Architecture**: Implemented Expense model, Provider, and Firestore integration.

### v1.3.8
- **Dashboard Drill-down**: Replaced the static daily revenue list with an expandable view showing services, discounts, and subtotals.
- **Photo Integration**: Integrated photo thumbnails into the daily invoice detail with full-screen viewing support.
- **Rendering Fixes**: Switched to `Wrap` layout for photos and added loading/error handling to stabilize web rendering.
- **CORS Management**: Configured production Storage CORS to ensure cross-origin image loading works correctly.

## Changelogs - April 29, 2026
### v1.3.2 - v1.3.6
- **Storage Integration**: Linked Firebase Storage with "Pay-as-you-go" plan and configured CORS via Google Cloud Shell to enable web uploads.
- **Photo Workflow**: Implemented photo capture/upload logic with conditional compression (under 200KB) and timeout handling (30s).
- **Gallery Management**: Added a "Photos" tab in Customer Detail page with centralized view and deletion support.
- **CRM Refinement**: Added "Edit Customer" functionality to update Name and Phone.
- **Database Architecture**: Standardized field names (photoUrls) and implemented backward compatibility logic for older records.
- **Bug Fixes**: Resolved 401 Permission errors, "Ghost" photo icons after deletion, and UI loading hangs.
- **Optimization**: Switched to Clean Build (`flutter clean`) process for production deployments to avoid stale artifacts.
