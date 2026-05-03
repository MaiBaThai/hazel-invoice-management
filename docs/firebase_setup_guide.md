# Firebase Setup & Configuration Guide (NMS)

This guide provides step-by-step instructions to configure Firebase for the Nail Management System (NMS).

## 1. Create a Firebase Project
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Click **Add project** and name it `NMS` (or your preferred name).
3. (Optional) Enable Google Analytics and click **Create project**.

## 2. Initialize Cloud Firestore
1. In the Firebase Console, navigate to **Build > Firestore Database**.
2. Click **Create database**.
3. Select **Start in test mode** for initial development (ensure you update rules later).
4. Choose a location nearest to your location and click **Enable**.

## 3. Install FlutterFire CLI
The FlutterFire CLI is the recommended way to configure Firebase for all Flutter platforms.

1. Install the Firebase CLI on your machine:
   ```bash
   npm install -g firebase-tools
   ```
2. Log in to Firebase:
   ```bash
   firebase login
   ```
3. Install the FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

## 4. Configure Platforms
Run the following command in the root of your Flutter project:
```bash
flutterfire configure
```
1. Select your project from the list.
2. Select the platforms: `web` and `ios` (as specified in requirements).
3. The CLI will automatically:
   - Create a `firebase_options.dart` file in `lib/`.
   - Register your apps in the Firebase Console.
   - Download the necessary configuration files.

## 5. Initialize Firebase in Flutter
Update your `lib/main.dart` to initialize Firebase before running the app:

```dart
// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(/* ... your app ... */);
}
```

## 6. Firestore Security Rules
To protect your data, go to **Firestore > Rules** and apply basic rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Basic rule: only authenticated users (if implemented later) or public during dev
    match /{document=**} {
      allow read, write: if true; // WARNING: Change this before production
    }
    
    // Recommended specific rules
    match /customers/{customerId} {
      allow read, write: if true;
    }
    
    match /invoices/{invoiceId} {
      allow read, create: if true;
    }
  }
}
```

## 7. Firebase Hosting (For PWA)
To deploy the web version:
1. Initialize Hosting:
   ```bash
   firebase init hosting
   ```
2. Select **Use an existing project**.
3. Set your public directory to `build/web`.
4. Configure as a single-page app: **Yes**.
5. Deploy:
   ```bash
   flutter build web
   firebase deploy
   ```

---
> [!TIP]
> For iOS, ensure you open `ios/Runner.xcworkspace` in Xcode and set your **Bundle Identifier** and **Team** to match your Apple Developer account.
