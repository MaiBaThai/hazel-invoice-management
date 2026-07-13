# Implementation Plan - iOS Subscription Integration

Implement a freemium subscription model for the Nail Management System (NMS) on iOS, utilizing RevenueCat to manage App Store purchases and active premium entitlements.

## User Review Required

> [!IMPORTANT]
> **RevenueCat & App Store Connect Setup**: The implementation requires:
> 1. A RevenueCat account and project linked to the App Store Connect app.
> 2. App Store Connect In-App Purchase products configured for:
>    - Monthly subscription (`$9.99/mo`)
>    - Yearly subscription (`$79.99/yr`)
> 3. Entitlements and Offerings set up on RevenueCat pointing to these App Store product IDs.
> 4. Setting up a RevenueCat Sandbox tester account on App Store Connect to test transactions on a physical iOS device.

## Open Questions

None. (All design tree branches have been resolved in the `/grill-me` session).

## Proposed Changes

### Dependencies

#### [MODIFY] [pubspec.yaml](file:///Users/maibathai/Documents/Personal/invoice/pubspec.yaml)
- Add `purchases_flutter` dependency.

---

### State & Service Layer

#### [NEW] [system_config_model.dart](file:///Users/maibathai/Documents/Personal/invoice/lib/data/models/system_config_model.dart)
- Model representing global remote app settings fetched from Firestore at `/system_configs/monetization`.
- Fields:
  - `subscription_enabled` (bool): Remote kill-switch. If `false`, bypasses all checks and grants full premium access to all users.
  - `active_offering_id` (string): Specific RevenueCat Offering ID to fetch, allowing dynamic price point shifts (e.g., A/B testing).
  - `free_invoice_limit` (int): Dynamic limit of free invoices per month (default `50`).

#### [NEW] [subscription_provider.dart](file:///Users/maibathai/Documents/Personal/invoice/lib/core/providers/subscription_provider.dart)
- Create a dedicated `SubscriptionProvider` with change notifier.
- Initialize RevenueCat SDK with the iOS API key.
- Fetch and listen to `/system_configs/monetization` (global config) and `/system_configs/access_control` (whitelist) from Firestore.
- Expose `bool isPremium` which returns `true` if:
  - Global `subscription_enabled` is `false`.
  - OR RevenueCat has an active premium entitlement.
  - OR the user's authenticated email is present in the `whitelisted_emails` array from the Firestore access_control document.
- Expose `int freeInvoiceLimit` (dynamic limit retrieved from system config, defaulting to `50`).
- Expose `bool isLoading`, `List<Package> offerings` (fetched dynamically based on `active_offering_id` from system config), `purchase(Package package)`, and `restorePurchases()`.
- Listen to real-time `CustomerInfo` updates from RevenueCat.

#### [MODIFY] [main.dart](file:///Users/maibathai/Documents/Personal/invoice/lib/main.dart)
- Register `SubscriptionProvider` in the `MultiProvider` block.
- Update `InvoiceProvider` and `CustomerProvider` setup to accept or listen to the `SubscriptionProvider` if needed.

---
### Gated Business Logic

#### [MODIFY] [invoice_provider.dart](file:///Users/maibathai/Documents/Personal/invoice/lib/core/providers/invoice_provider.dart)
- Inject/dependency-link `SubscriptionProvider`.
- Add `Future<int> getInvoiceCountForCurrentMonth()` query to Firestore using `.count().get()` on `invoices` created on or after the 1st of the current month (or from local cache if offline).
- Expose `Future<bool> checkCanSaveInvoice()` which checks if the user is premium or if `getInvoiceCountForCurrentMonth() < subscriptionProvider.freeInvoiceLimit`. This allows pre-save validation in UI.

#### [MODIFY] [customer_provider.dart](file:///Users/maibathai/Documents/Personal/invoice/lib/core/providers/customer_provider.dart)
- Inject/dependency-link `SubscriptionProvider`.
- Check `subscriptionProvider.isPremium` before executing `uploadPhotoForInvoice()`. If not premium, block photo picker/upload and trigger paywall.
---

### UI & Gating Components

#### [NEW] [paywall_bottom_sheet.dart](file:///Users/maibathai/Documents/Personal/invoice/lib/features/subscription/widgets/paywall_bottom_sheet.dart)
- Create a premium-styled slide-up bottom sheet with:
  - Feature comparison (Free vs. Premium).
  - Billing toggle (Monthly vs. Yearly).
  - Prominent "Subscribe" button.
  - "Restore Purchases" button for App Store compliance.
  - Legal links (Terms of Use/EULA, Privacy Policy).

#### [NEW] [subscription_settings_page.dart](file:///Users/maibathai/Documents/Personal/invoice/lib/features/settings/subscription_settings_page.dart)
- Full-screen subscription status page accessible from Settings.
- Displays current plan (Free vs. Premium), expiration date, and billing options.

#### [MODIFY] [invoice_page.dart](file:///Users/maibathai/Documents/Personal/invoice/lib/features/invoice/invoice_page.dart)
- For free users, display a compact monthly usage progress bar (e.g. `24 / ${subscriptionProvider.freeInvoiceLimit} invoices free this month`).

#### [MODIFY] [invoice_summary_dialog.dart](file:///Users/maibathai/Documents/Personal/invoice/lib/features/invoice/widgets/invoice_summary_dialog.dart)
- In the "CONFIRM & SAVE" action, run `checkCanSaveInvoice()`. If it returns `false` (monthly limit reached), cancel the save action and slide up `PaywallBottomSheet` with a clear explanation: *"You have reached the monthly free limit of ${subscriptionProvider.freeInvoiceLimit} invoices. Upgrade to Premium to save this invoice and unlock unlimited invoices."*
- Modify the post-save `_showPhotoPrompt` dialog for free/unsubscribed users:
  - Customize dialog content to read: *"Invoice Saved! (Photo journaling is a Premium feature. Upgrade to Premium to attach work photos to this customer's visual archive)."*
  - Replace the standard "📷 TAKE PHOTO" button with "📷 GO PREMIUM", which redirects the user to the paywall bottom sheet.

#### [MODIFY] [customer_detail_page.dart](file:///Users/maibathai/Documents/Personal/invoice/lib/features/customers/customer_detail_page.dart)
- In the Customer details tabs, place a lock icon on the "Photos" tab for free users.
- Tapping the locked Photos tab or photo upload action opens `PaywallBottomSheet`.

#### [MODIFY] [dashboard_page.dart](file:///Users/maibathai/Documents/Personal/invoice/lib/features/dashboard/dashboard_page.dart)
- Show locks or blurred overlays on gated components (14D/30D/90D filters, heat map, podium charts) for free users.
- Tapping them triggers `PaywallBottomSheet`.

#### [MODIFY] [settings_page.dart](file:///Users/maibathai/Documents/Personal/invoice/lib/features/settings/settings_page.dart)
- Add a settings card: "My Subscription" displaying current tier.
- Tapping it pushes `SubscriptionSettingsPage`.

---

## Verification Plan

### Automated Tests
- Create `test/subscription_provider_test.dart` to mock RevenueCat SDK responses.
- Verify limit checking logic in `test/invoice_limit_test.dart` by mocking invoice count responses.

### Manual Verification
- Deploy to a physical iOS device via TestFlight.
- Log in with an App Store Connect sandbox tester account.
- Perform a simulated purchase of Monthly and Yearly subscriptions.
- Validate that premium features instantly unlock and locks disappear from the UI.
- Test "Restore Purchases" flow.
- Simulate offline mode, verify that Firestore local cache count successfully enforces the 50 invoice limit.
