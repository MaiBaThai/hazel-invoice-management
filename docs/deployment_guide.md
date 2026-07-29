# Deployment & Development Guide for Nail Management System (NMS)

This guide provides the standard procedures for building, testing, deploying, and release-managing the NMS application for both **Web (Firebase Hosting)** and **iOS (App Store Connect)**.

---

## 1. Prerequisites

### Global

- **Flutter SDK**: Installed and updated.
- **Firebase CLI**: Installed (`npm install -g firebase-tools`) and logged in (`firebase login`).
- **FlutterFire CLI**: Activated (`dart pub global activate flutterfire_cli`).

### iOS Development Only

- **macOS Machine**: Running the latest macOS version.
- **Xcode IDE**: Installed from the Mac App Store.
  - Active path configured: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
  - Components installed: `sudo xcodebuild -runFirstLaunch`
  - iOS Simulator Runtime downloaded via Xcode Settings (Platforms tab) or via Command Line: `xcodebuild -downloadPlatform iOS`
- **CocoaPods**: Installed via Homebrew: `brew install cocoapods`

---

## 2. Environment Management

We use Firebase aliases and Flutter flavors to switch between environments.

| Environment     | Firebase Project            | iOS Bundle ID               | iOS Scheme | Flutter Run Command                                        |
| :-------------- | :-------------------------- | :-------------------------- | :--------- | :--------------------------------------------------------- |
| **Development** | `invocie-management`        | `com.maibathai.invoice.dev` | `dev`      | `flutter run --flavor dev --dart-define=ENVIRONMENT=dev`   |
| **Production**  | `invoices-management-c4ef0` | `com.maibathai.invoice`     | `prod`     | `flutter run --flavor prod --dart-define=ENVIRONMENT=prod` |

```bash
# Verify active Firebase project
firebase use

# Switch Firebase environment
firebase use development
firebase use production
```

---

## 3. Web Build & Deployment Workflow

### Step 1: Clean and Fetch Dependencies

Always run in the project root:

```bash
flutter clean
flutter pub get
```

### Step 2: Build for Web

Specify the target environment using `--dart-define`.

```bash
# Development build
flutter build web --release --no-tree-shake-icons --dart-define=ENVIRONMENT=dev

# Production build
flutter build web --release --no-tree-shake-icons --dart-define=ENVIRONMENT=prod
```

### Step 3: Deploy to Firebase Hosting

```bash
# Deploy to Dev
firebase use development
firebase deploy --only hosting,firestore,storage

# Deploy to Prod
firebase use production
firebase deploy --only hosting,firestore,storage
```

---

## 4. iOS Development, Testing & Release Workflow

### Step 1: Local Development & Simulator Testing

1. Launch the iOS Simulator:
   ```bash
   open -a Simulator
   ```
2. Verify the Simulator is active:
   ```bash
   flutter devices
   ```
3. Run the development or production environment:

   ```bash
   # Development build
   flutter run --flavor dev --dart-define=ENVIRONMENT=dev --no-enable-impeller

   # Production build
   flutter run --flavor prod --dart-define=ENVIRONMENT=prod --no-enable-impeller
   ```

### Step 2: Build Release Bundle

To generate the `.ipa` package for App Store Connect distribution:

```bash
# Clean project
flutter clean
flutter pub get

# Generate App Store distribution bundle
flutter build ipa --flavor prod
```

_This command outputs the compiled archive to `build/ios/ipa/Runner.ipa`._

### Step 3: Upload to App Store Connect / TestFlight

There are two ways to upload the compiled bundle to Apple:

#### Option A: Via Transporter App (Recommended)

1. Download the **Transporter** app from the Mac App Store.
2. Open Transporter and log in with your Apple ID.
3. Drag and drop the generated `build/ios/ipa/Runner.ipa` file into Transporter.
4. Click **Deliver**.

#### Option B: Via Xcode Organizer

1. Open the project workspace: `open ios/Runner.xcworkspace`.
2. Select **Any iOS Device (arm64)** as the target.
3. Go to the top menu: **Product** -> **Archive**.
4. Once archiving is complete, the **Organizer** window opens. Select your archive and click **Distribute App** to upload it.

---

## 5. Storage & CORS Configuration (Web Only)

The Web app requires CORS to be configured on Firebase Storage to allow cross-origin uploads/downloads. iOS uses native HTTP channels and does not require this.

1. Ensure a `cors.json` file exists in your project root:
   ```json
   [
     {
       "origin": ["*"],
       "method": ["GET", "POST", "PUT", "DELETE", "HEAD"],
       "maxAgeSeconds": 3600
     }
   ]
   ```
2. Set CORS configuration via Google Cloud CLI (`gcloud storage`):

   ```bash
   # Development Storage
   gcloud storage buckets update gs://invocie-management.firebasestorage.app --cors-file=cors.json

   # Production Storage
   gcloud storage buckets update gs://invoices-management-c4ef0.firebasestorage.app --cors-file=cors.json
   ```

---

## 6. Git Version Control Workflow

To keep your code clean, prevent merge conflicts in `project.pbxproj`, and maintain proper releases:

### 1. Feature Development

Always build new features or fixes on a branch from `develop`:

```bash
# Create and switch to a feature branch
git checkout develop
git pull origin develop
git checkout -b feature/your-feature-name
```

### 2. Resolving Xcode Project Merge Conflicts

`project.pbxproj` is a database of UUID references and is prone to conflicts when working on multiple branches.

- Before committing, verify your Xcode project settings syntax is correct:
  ```bash
  plutil -lint ios/Runner.xcodeproj/project.pbxproj
  ```
- If you have conflicts in `project.pbxproj` during a merge:
  1. Open Xcode.
  2. In many cases, Xcode will highlight the compilation issues or refuse to open the project.
  3. Keep the base configuration and manually merge changes, keeping both added configurations/files.

### 3. Deploying to Test Environments

- Web: Build and deploy to the **Development** Firebase hosting for user validation.
- iOS: Build the dev flavor and test locally on Simulator or physical devices using TestFlight dev tracks.

### 4. Merging and Releasing

When a feature is verified:

1. Merge the feature branch back into `develop` using a Pull Request.
2. When ready for a major release, merge `develop` into `main`.
3. Tag the release:
   ```bash
   git checkout main
   git pull origin main
   # Create a tag matching the version in pubspec.yaml
   git tag -a v1.9.0 -m "Release version 1.9.0 - iOS Core Setup"
   git push origin v1.9.0
   ```
4. Build and deploy the **Production** web bundle and upload the production `.ipa` package to App Store Connect.

---

## 7. Troubleshooting iOS Builds

- **CocoaPods Dependency Conflict (gRPC/BoringSSL missing modules)**:
  If a clean build fails on CocoaPods compilation, clean the caches and recreate the pods environment:
  ```bash
  flutter clean
  rm -rf ios/Pods ios/Podfile.lock
  pod cache clean --all
  flutter pub get
  cd ios
  pod install --repo-update
  ```
- **Flavor Scheme Missing Error**:
  If Xcode says `The Xcode project does not define custom schemes.`, ensure the custom scheme files (`dev.xcscheme` and `prod.xcscheme`) are present in `ios/Runner.xcodeproj/xcshareddata/xcschemes/`. You can recreate them using:
  ```bash
  python3 scratch/create_schemes.py
  ```
- **"cloud_firestore requires a higher minimum deployment version"**:
  If building fails due to version target restrictions, ensure `IPHONEOS_DEPLOYMENT_TARGET` is set to `15.0` or higher in `project.pbxproj`. You can enforce this globally using:
  ```bash
  python3 scratch/configure_xcodeproj.py
  ```
