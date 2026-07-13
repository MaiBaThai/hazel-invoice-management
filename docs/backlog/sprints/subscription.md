# Sprint: iOS Subscription Feature

This sprint covers the initial implementation of the monetization system, focused specifically on the **native iOS build** of the Nail Management System (NMS). This system is not applicable to the Web App version.

## Sprint Goal
Build a subscription system for the mobile app to allow users to subscribe to a monthly or yearly plan, restricting free-tier usage while offering advanced features to paying users.

---

## User Stories
- **STORY-SUB-001**: As a user, I want to be able to subscribe to a monthly plan.
- **STORY-SUB-002**: As a user, I want to be able to subscribe to a yearly plan.
- **STORY-SUB-003**: As a user, I want to be able to see my current subscription plan.
- **STORY-SUB-004**: As a user, I want to be able to restore my purchases when reinstalling the app.
- **STORY-SUB-005**: As a user, I want to see the benefits of each subscription plan on a paywall screen.
- **STORY-SUB-006**: As a free user, I want to see how many of my monthly free invoices I have used.

---

## Subscription Model Specifications

### Free Tier (Solo/Individual)
- **Authentication**: Guest mode (Anonymous Auth) or standard Apple/Google secure logins.
- **Monthly Invoice Limit**: Max 50 invoices per calendar month (resets on the 1st of every month). "Save as Image" and VietQR functions remain fully active.
- **Photo Uploads**: Disabled (Premium feature).
- **Dashboard Reporting (Fully Unlocked)**:
  - Daily & Monthly total revenue and expenses.
  - Trailing 7-day revenue bar chart.
  - Extended date filtering: 14D Daily, 30D/90D Weekly, and YTD/All-Time Monthly views.
  - Busiest Days & Times Heat Map.
  - Top 3 Services Podium Chart.
  - Performance Metrics: Average Ticket Value (ATV) and Net Profit Margin.
- **Other Limits**:
  - No export data capability (CSV/Excel).
  - Standard invoice branding (no custom logo uploads).

### Paid (Studio) Tier
- **Pricing**:
  - **Monthly Plan**: $2.99 / month
  - **Yearly Plan**: $19.99 / year (~45% discount)
- **Resource Limits**: Unlimited invoices, customers, and expenses.
- **Photo Storage**: Enabled. Includes up to 10 GB Storage limit (~50,000 highly-compressed photos).
- **Premium Capabilities**:
  - Custom branding: Upload salon logo and custom notes for VietQR invoices.
  - Multi-user collaboration (adding Staff/Manager profiles with roles).
  - Export reports to CSV/Excel for accounting.

---

## Technical Decisions (Resolved in Brainstorming)

1. **Integration Library**: Use **RevenueCat (`purchases_flutter`)** to manage App Store products, process purchases, handle receipt validation, and track entitlements.
2. **Entitlement State Management**: A new, dedicated `SubscriptionProvider` will handle initialization, purchase processing, and entitlement state tracking. It will expose a boolean getter `isPremium` that evaluates to true if:
   - The global subscription is remotely disabled.
   - OR RevenueCat has an active premium entitlement.
   - OR the user's signed-in email is in the Firestore `system_configs/access_control/whitelisted_emails` whitelist.
3. **Limit Enforcement**:
   - Limit checks will be handled in Dart provider classes (`InvoiceProvider` and `CustomerProvider`) based on the active entitlement status.
   - Monthly invoice counts will be fetched using a fast, cheap Firestore `.count().get()` query.
4. **Offline Support**: Firestore's offline cache query will be used to enforce monthly limits when a user's device is offline (checking local cache counts).
5. **Gating UI (Teaser & Lock)**: Only premium features (e.g., Photos tab) will remain visible to free users with a lock icon. Tapping them will trigger the paywall. All current Dashboard analytics are fully unlocked for all users in this phase.
6. **Paywall UX**:
   - **Reactive (Limit Trigger)**: A contextual slide-up Bottom Sheet when a user hits a limit or taps a locked feature.
   - **Proactive (Active Opt-In)**: A dedicated full-screen "My Subscription" page pushed from the Settings tab.
7. **Testing Strategy**: All billing configurations and entitlement changes will be tested directly using **App Store Connect Sandbox** on a physical iOS test device.
