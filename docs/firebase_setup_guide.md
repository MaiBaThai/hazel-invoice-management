# Firebase Setup & Configuration Guide (NMS)

This guide provides step-by-step instructions to configure Firebase for the Nail Management System (NMS).

## 1. Project Environments

We maintain two separate Firebase projects to isolate development/testing from production data.

| Environment | Project Name | Project ID | Purpose |
| :--- | :--- | :--- | :--- |
| **Production** | invoices-management | `invoices-management-c4ef0` | Live environment for end-users. |
| **Development** | invocie-management-dev | `invocie-management` | Testing new features and changes. |

## 2. Version Control (Git)

The source code is hosted on GitHub.

- **Repository**: `https://github.com/MaiBaThai/hazel-invoice-management`
- **Branching Strategy**:
    - `main`: Production-ready code. Always stable.
    - `develop`: Main development branch. Features are merged here first.

## 3. Initialize Cloud Firestore & Storage

### Firestore
1. In the Firebase Console, navigate to **Build > Firestore Database**.
2. Click **Create database**.
3. Select a location (Production: `nam5`, Development: `nam5`).
4. Apply security rules using the Firebase CLI (see Deployment Guide).

### Storage
1. In the Firebase Console, navigate to **Build > Storage**.
2. Click **Get Started**.
3. Select a location and apply security rules via CLI.

## 4. Install FlutterFire CLI

The FlutterFire CLI is the recommended way to configure Firebase for all Flutter platforms.

1. Install the Firebase CLI:
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

## 5. Configure Environments (Dart Defines)

Instead of a single `firebase_options.dart`, we use environment-specific files:

1. **Development**:
   ```bash
   flutterfire configure --project=invocie-management --out=lib/firebase_options_dev.dart --platforms=web
   ```
2. **Production**:
   ```bash
   flutterfire configure --project=invoices-management-c4ef0 --out=lib/firebase_options_prod.dart --platforms=web
   ```

## 6. Initialize Firebase in Flutter

Update `lib/main.dart` to support multiple environments:

```dart
import 'firebase_options_dev.dart' as dev;
import 'firebase_options_prod.dart' as prod;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Use --dart-define=ENVIRONMENT=prod to switch to production
  const String environment = String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');
  
  await Firebase.initializeApp(
    options: environment == 'prod' 
        ? prod.DefaultFirebaseOptions.currentPlatform 
        : dev.DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const NMSApp());
}
```
