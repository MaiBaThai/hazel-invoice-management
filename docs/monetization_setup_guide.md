# Setup Guide: iOS Subscriptions (App Store Connect & RevenueCat)

This guide walks you through setting up Apple App Store Connect and RevenueCat to enable subscriptions in the Nail Management System (NMS).

---

## Part 1: App Store Connect Configuration

### 1. Create a Subscription Group
To sell subscriptions, Apple requires them to belong to a "Subscription Group". Users can only subscribe to one product within a group at a time.
1. Log in to [App Store Connect](https://appstoreconnect.apple.com/).
2. Select your app under **My Apps**.
3. In the sidebar, go to **Features** > **Subscriptions**.
4. Under **Subscription Groups**, click **Create**.
5. Name the group (e.g., `Premium Access`) and click **Create**.

### 2. Create Your Subscription Products
Create the monthly and yearly tiers inside your new subscription group.
1. Inside the group, click **Create** under the **Subscriptions** table.
2. Enter the details:
   - **Reference Name**: `Monthly Premium` / `Yearly Premium` (for internal use).
   - **Product ID**: `mysalonapp_premium_monthly` / `mysalonapp_premium_yearly` (as shown in App Store Connect Subscriptions).
3. Set the duration:
   - For Monthly: **1 Month**.
   - For Yearly: **1 Year**.
4. Configure Pricing:
   - Click **Add Subscription Price**.
   - Select your base price (e.g., USD 9.99 / USD 79.99).
5. Add App Store Localization:
   - Click the **+** icon in the **Localization** section to add supported storefront languages (English (U.S.) and Vietnamese are required).
   - Enter the localized **Display Name** and **Description** as outlined below:

   #### English (U.S.) Localization
   *   **Monthly Subscription (`mysalonapp_premium_monthly`)**
       *   **Display Name**: `Premium Monthly Access`
       *   **Description**: `Unlock unlimited invoices, photos, and analytics.` (49 chars)
   *   **Yearly Subscription (`mysalonapp_premium_yearly`)**
       *   **Display Name**: `Premium Yearly Access`
       *   **Description**: `One year of unlimited invoices, photos & analytics.` (51 chars)

   #### Vietnamese Localization
   *   **Monthly Subscription (`mysalonapp_premium_monthly`)**
       *   **Display Name**: `Premium Theo Tháng`
       *   **Description**: `Mở khóa hóa đơn không giới hạn, ảnh và thống kê.` (48 chars)
   *   **Yearly Subscription (`mysalonapp_premium_yearly`)**
       *   **Display Name**: `Premium Theo Năm`
       *   **Description**: `Trọn gói premium 1 năm: hóa đơn, ảnh & thống kê.` (48 chars)

6. Click **Save**.

### 3. Generate App Store Connect In-App Purchase Key (StoreKit 2)
RevenueCat requires this private key (.p8 file) to communicate with Apple's App Store Server API (StoreKit 2) to securely validate transactions and manage subscriptions.
1. Log in to [App Store Connect](https://appstoreconnect.apple.com/).
2. Go to **Users and Access** from the main dashboard.
3. Select the **Integrations** (or **Keys**) tab at the top.
4. On the left sidebar under *Keys*, select **In-App Purchase**.
5. Click **Generate In-App Purchase Key** (or the **+** icon).
6. Enter a name for the key (e.g., `RevenueCat Key`) and click **Generate**.
7. Once generated:
   - Click **Download** to download the `.p8` key file. *Note: You can only download this file once, so store it securely.*
   - Copy the **Key ID** (a 10-character code next to your key).
   - Copy the **Issuer ID** (the long UUID string visible at the top of the page).

---

## Part 2: RevenueCat Configuration

### 1. Create an App in RevenueCat
1. Log in to the [RevenueCat Dashboard](https://app.revenuecat.com/).
2. Click **Create Project** or select your existing project.
3. Under the **Apps** page, click the **New app configuration** card.
4. Choose **App Store** (iOS).
5. Fill in the App Details:
   - **App Name**: `Nail Management System`
   - **App Bundle ID**: `com.maibathai.invoice` (as defined in your `GoogleService-Info.plist`).
6. In the **In-app purchase key configuration** section:
   - Upload the `.p8` key file downloaded in Part 1.
   - Enter the **Key ID** and **Issuer ID**.
7. *(Optional)* Under **App-specific shared secret (Legacy)**, you can still add a legacy shared secret if you want to support devices on iOS 14 or below.
8. Click **Save changes**.

### 2. Create Entitlements
Entitlements represent the features unlocked by a purchase.
1. Go to **Entitlements** in the sidebar and click **New**.
2. **Identifier**: `My Salon - Salon Management Pro` (we will check this exact string in the Flutter code).
3. **Description**: `Unlocks all premium features (photos, unlimited invoices, advanced analytics)`.
4. Click **Add**.

### 3. Map Products
Import your App Store products into RevenueCat.
1. Go to **Products** in the sidebar and click **New**.
2. Select your **App Store** app.
3. **Identifier**: Enter the exact App Store Product ID (e.g., `mysalonapp_premium_monthly`).
4. Click **Add**.
5. Repeat for the yearly product (`mysalonapp_premium_yearly`).

### 4. Link Products to Entitlements
1. Go to **Entitlements** > click on `My Salon - Salon Management Pro`.
2. Click **Attach Product**.
3. Select your monthly product. Repeat and attach your yearly product.
4. Click **Attach**.

### 5. Configure Offerings
Offerings are groups of packages presented to the user.
1. Go to **Offerings** in the sidebar and click **New**.
2. **Identifier**: `default` (or `promo_test` for A/B testing).
3. **Description**: `Default pricing offering`.
4. Click **Add**.
5. Click on your newly created offering.
6. Click **New Package**.
   - **Identifier**: `$monthly`
   - **Product**: Choose the mapped monthly product.
7. Click **New Package** again.
   - **Identifier**: `$yearly`
   - **Product**: Choose the mapped yearly product.
8. Set this offering as **Active** (default).

---

## Part 3: Testing Sandbox Subscriptions

1. In App Store Connect, go to **Users and Access** > **Sandbox** > **Sandbox Testers**.
2. Click **+** to add a new tester. Fill in the details (use a real email address you have access to, but one that is not linked to an active Apple ID).
3. On your physical iOS test device:
   - Go to **Settings** > **App Store**.
   - Scroll down to the **Sandbox Account** section and sign in with your tester email.
4. Build the app using Xcode, run it on the physical device, and trigger the purchase flow.

---

## Part 4: App Store Connect Billing, Tax & Compliance Guide (Vietnam Focus)

This section provides critical answers and setup instructions for Vietnamese individual developers distributing monetization apps worldwide.

### 1. Requirements for Testing Billing Flow (Sandbox vs. TestFlight)
*   **Xcode StoreKit Testing (Local/Offline)**: **No account setup required**. You can test purchases completely offline using an Xcode StoreKit Configuration (`.storekit` file) without setting up banking or tax info on App Store Connect.
*   **App Store Connect Sandbox (Xcode build on physical device)**: **Paid Apps Agreement does not need to be Active**. You can test using App Store Connect Sandbox accounts as long as products are created.
*   **TestFlight & Production**: **Paid Apps Agreement must be ACTIVE**. If you test on TestFlight, the App Store servers handle the transaction validation. If your Paid Apps Agreement is in "Pending User Info" status, TestFlight purchases will fail to fetch or yield errors because App Store Connect blocks monetization until banking and tax details are finalized.

### 2. Bank Account Setup in Vietnam
*   **Support**: Apple fully supports payouts to Vietnamese personal bank accounts in either USD or VND (which is converted automatically by your Vietnamese bank at their spot exchange rate).
*   **Key Setup Notes**:
    *   **Account Holder Name**: Must match exactly the name on your Apple Developer Account (`Thai Maiba`) and your bank records, written in UPPERCASE English characters without accents (e.g., `THAI MAI BA` or `MAI BA THAI`).
    *   **SWIFT BIC & Bank Name**: Look up the exact SWIFT Code and official English name of your bank.
    *   **Vietcombank vs. MB Bank**:
        *   **Vietcombank (Recommended)**: The industry gold standard for receiving international wire transfers/remittances in Vietnam. They are highly reliable, have robust systems for incoming USD transfers, and are very experienced with Apple/Google payouts. *Note: For very large first-time transfers, they might request you to email them screenshots of your App Store Connect agreements/sales reporting as source proof.*
        *   **MB Bank**: Good modern interface and sometimes offers zero foreign wire transaction fees, but is occasionally less experienced in processing manual documentation audits for foreign inward remittances.
        *   *Verdict*: Choose **Vietcombank** for maximum stability and peace of mind.

### 3. Paid Apps Agreement "Pending User Info" Status
*   **Action Required**: You must wait for this status to turn **Active** before releasing your app or testing on TestFlight.
*   To change it to **Active**, you must complete:
    1. **Add Bank Account** information.
    2. **Complete Tax Forms** (primarily the U.S. Tax Questionnaire).
*   Once submitted, Apple processes the info within 24-48 hours, changing the status to "Processing" and then "Active".

### 4. Country & Regional Release Considerations
You target release in: Canada, US, France (FR), Germany (DE), United Kingdom (UK), Spain, Vietnam, Indonesia, Malaysia, Philippines, Singapore, Thailand, Taiwan.
*   **EU & UK (FR, DE, Spain, UK) - Digital Services Act (DSA)**:
    *   **Mandatory Declaration**: Since you distribute in the EU and monetize your app, Apple/EEA requires you to declare as a **Trader** under the DSA.
    *   **Public Contact Info**: If declared as a Trader, your personal contact details (physical address, phone number, email) will be publicly visible on the App Store product pages.
*   **VAT & Local Digital Taxes (EU, UK, Canada, US, Southeast Asia, Taiwan)**:
    *   Apple acts as the **Merchant of Record** (reseller) and handles local tax collection and remittance automatically for Canada, US (Sales Tax), EU/UK (VAT), Singapore (GST), Malaysia (Service Tax), Indonesia (VAT), Thailand (VAT), and Taiwan (VAT).
*   **Vietnam Storefront Tax (VN)**:
    *   Since 2022, Apple automatically deducts and pays the 5% VAT and 5% CIT (Foreign Contractor Tax) directly to the Vietnamese government for purchases in the VN storefront. This 10% is deducted from the customer price before Apple calculates your 70% share.
*   **Pricing Localization**:
    *   Use Apple's localized pricing grids. While $2.99 is low-friction for US/CA users, it may feel expensive for users in Vietnam, Indonesia, or Philippines. Consider setting manually lower price points for developing markets (e.g., 39k VND / 49k VND in Vietnam) to optimize conversion.

### 5. Tax Declarations for Vietnamese Citizens
*   **US Tax Form (W-8BEN)**:
    *   On App Store Connect, complete the **U.S. Tax Questionnaire** which generates form **W-8BEN** for individuals.
    *   **Crucial Step**: In the "Foreign Tax Identifying Number (TIN)" field, enter your **Vietnamese Personal Tax ID (Mã số thuế cá nhân)**. Under the US-Vietnam tax treaty, this reduces the U.S. withholding tax rate on US-derived royalty income from 30% down to a lower treaty rate (usually 10%).
*   **Other Foreign Storefronts**:
    *   You do **not** need to register or file taxes individually in the US, Canada, EU, UK, or other countries. Apple handles it.
*   **Vietnam Local Tax (PIT & VAT)**:
    *   Earnings received in your Vietnamese bank account are subject to Vietnamese tax under **Thông tư 40/2021/TT-BTC** for individuals earning from global digital platforms.
    *   **Tax Rate**: Flat **7%** of your total received revenue (5% VAT + 2% PIT).
    *   **Exemption Threshold**: If your total revenue from business activities (including App Store earnings and other MMO/freelance income) is **under 100 million VND per calendar year (or 0 VND)**, you are **exempt** from both VAT and PIT. No tax payments are due.
    *   **Filing**: You only need to register and declare/pay taxes once your actual revenue starts flowing in and is projected to exceed the 100M VND/year threshold. Vietnamese tax departments now actively cross-reference bank accounts for MMO/Developer revenues, so proactive filing is highly recommended once you pass the threshold.
