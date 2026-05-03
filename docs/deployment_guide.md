# Deployment Guide for Nail Management System (NMS)

This guide provides the standard procedure for building and deploying the NMS Flutter Web application to Firebase Hosting. Following these steps ensures a clean build and avoids common caching or permission issues.

## 1. Prerequisites
- **Flutter SDK**: Ensure Flutter is installed and updated.
- **Firebase CLI**: Installed (`npm install -g firebase-tools`) and logged in (`firebase login`).
- **FlutterFire CLI**: Activated (`dart pub global activate flutterfire_cli`).

## 2. Environment Management (Aliases)

We use Firebase aliases to switch between projects easily.

```bash
# Check current project
firebase use

# Switch to development
firebase use development

# Switch to production
firebase use production
```

## 3. Standard Deployment Workflow

Always run these commands in the project root directory.

### Step A: Clean & Prepare
```bash
flutter clean
flutter pub get
```

### Step B: Build for Web
Specify the environment using `--dart-define`.

**For Development:**
```bash
flutter build web --release --no-tree-shake-icons --dart-define=ENVIRONMENT=dev
```

**For Production:**
```bash
flutter build web --release --no-tree-shake-icons --dart-define=ENVIRONMENT=prod
```

### Step C: Deploy to Hosting

**Deploy to Development:**
```bash
firebase use development
firebase deploy --only hosting,firestore,storage
```

**Deploy to Production:**
```bash
firebase use production
firebase deploy --only hosting,firestore,storage
```

## 4. Storage & CORS Configuration
The Web app requires CORS to be configured on Firebase Storage to allow uploads/downloads.

### Local Command:
1. Create a `cors.json` file:
```json
[
  {
    "origin": ["*"],
    "method": ["GET", "POST", "PUT", "DELETE", "HEAD"],
    "maxAgeSeconds": 3600
  }
]
```
2. Run for Dev: `gsutil cors set cors.json gs://invocie-management.firebasestorage.app`
3. Run for Prod: `gsutil cors set cors.json gs://invoices-management-c4ef0.firebasestorage.app`

## 5. Version Control Workflow
1. Create a feature branch from `develop`.
2. Build and deploy to **Development** environment for testing.
3. Merge feature branch into `develop`.
4. When ready for release, merge `develop` into `main`.
5. Build and deploy to **Production** environment.
6. Tag the release: `git tag -a v1.3.7 -m "Release version 1.3.7"`

## 6. Troubleshooting
- **Caching**: Increment the version string in `lib/main.dart` or `invoice_page.dart` to force a service worker update.
- **Wrong Project**: Always run `firebase use` before deploying to verify the target project.
- **Environment Mismatch**: Ensure your `--dart-define` matches the `firebase use` target.
