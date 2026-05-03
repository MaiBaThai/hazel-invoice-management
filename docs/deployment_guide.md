# Deployment Guide for Nail Management System (NMS)

This guide provides the standard procedure for building and deploying the NMS Flutter Web application to Firebase Hosting. Following these steps ensures a clean build and avoids common caching or permission issues.

## 1. Prerequisites
- **Flutter SDK**: Ensure Flutter is installed and updated.
- **Firebase CLI**: Installed (`npm install -g firebase-tools`) and logged in (`firebase login`).
- **GCloud SDK** (Optional): Useful for advanced storage configuration (`gcloud auth login`).

## 2. Standard Deployment Workflow

Always run these commands in the project root directory.

### Step A: Clean & Prepare
Clearing previous build artifacts is mandatory to prevent stale code being served to users.
```bash
flutter clean
flutter pub get
```

### Step B: Build for Web
Use the release mode with specific flags for consistent results.
```bash
flutter build web --release --no-tree-shake-icons --no-wasm-dry-run
```
*Note: `--no-tree-shake-icons` prevents icon rendering issues on some browsers.*

### Step C: Deploy to Hosting
Deploy to the main production URL and optionally a preview channel for testing.

**Production Deploy:**
```bash
firebase deploy --only hosting
```

**Preview Channel (Recommended for testing):**
```bash
# Replace 'v136' with your current version tag
firebase hosting:channel:deploy v136 --expires 1h
```

## 3. Storage & CORS Configuration
If you ever create a new bucket or reset settings, the Web app requires CORS to be configured to allow uploads.

### Local Command (Requires GCloud Login):
1. `gcloud auth login`
2. Create a `cors.json` file:
```json
[
  {
    "origin": ["*"],
    "method": ["GET", "POST", "PUT", "DELETE", "HEAD"],
    "maxAgeSeconds": 3600
  }
]
```
3. Run: `gsutil cors set cors.json gs://invoices-management-c4ef0.firebasestorage.app`

### Quick Fix via Google Cloud Shell:
Copy and paste this into the Firebase Cloud Shell:
```bash
echo '[{"origin": ["*"],"method": ["GET", "POST", "PUT", "DELETE", "HEAD"],"maxAgeSeconds": 3600}]' > cors.json && gsutil cors set cors.json gs://invoices-management-c4ef0.firebasestorage.app
```

## 4. Troubleshooting Caching Issues
If you deploy but don't see changes:
1. **Version Bump**: Increment the version string in `lib/features/invoice/invoice_page.dart`.
2. **Hard Refresh**: Press `Cmd + Shift + R` (Mac) or `Ctrl + F5` (Windows) in the browser.
3. **Incognito Mode**: Test in a private window to bypass local storage/service workers.
4. **Clean Build**: Ensure you ran `flutter clean` before building.
