# Product Backlog: Nail Management System (NMS)

This document outlines the features and user stories for the NMS, prioritized for development.

## Epic 1: Invoice Management (Core MVP)
*Goal: Allow users to record services and generate invoices efficiently.*

- [x] **STORY-001**: As a user, I want to search for existing customers or add new ones during invoice entry.
- [x] **STORY-002**: As a user, I want to add multiple services to an invoice with dynamic price calculation.
- [x] **STORY-003**: As a user, I want to apply a discount percentage to the total invoice amount.
- [x] **STORY-004**: As a user, I want to save invoices to Firestore and have the customer's `total_spent` updated automatically.
- [x] **STORY-005**: As a user, I want to see a beautiful summary view of the invoice with a payment QR code and an option to save as image.

## Epic 2: Reporting & Dashboard
*Goal: Provide insights into business performance.*

- [x] **STORY-006**: As a user, I want to see total revenue stats by Day, Month, and Year.
- [x] **STORY-007**: As a user, I want a visual bar chart showing revenue for the last 7 days.
- [x] **STORY-008**: As a user, I want to search customer history by Name or Phone number.
- [x] **STORY-009**: As a user, I want to view a chronological list of all past invoices for a specific customer.

## Epic 3: Configuration & Settings [DONE]
- [x] Story 1: As a user, I want to edit/delete customer information to maintain a clean database.
- [x] Story 2: As a user, I want to configure my bank account for VietQR generation dynamically.
- [x] Story 3: As a user, I want to manage a predefined list of services (Service Menu) for quick entry.
- [x] Story 4: As a user, I want quick-add chips in the invoice tab to speed up entry.

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
- [ ] **STORY-022**: As a user, I want to see the impact of expenses on my daily/monthly profit on the Dashboard.

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
