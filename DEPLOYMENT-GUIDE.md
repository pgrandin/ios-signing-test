# iOS App Deployment Guide

Complete guide for the automated iOS build and deployment pipeline.

## What We Built

### Branch: `qt6-hello-world`
A native iOS UIKit app that displays:
- "Hello World from iOS!" (large blue text)
- "Built with GitHub Actions" (subtitle)
- Full GUI that stays open on device

### Automation Scripts

#### 1. **Full Deployment Cycle** (`full-deploy-cycle.sh`)
Complete end-to-end automation:
```bash
./full-deploy-cycle.sh [branch-name]
```

**What it does:**
1. Triggers GitHub Actions build
2. Monitors build progress
3. Downloads signed IPA when ready
4. Waits for device connection
5. Deploys to device
6. Verifies installation

**Example:**
```bash
./full-deploy-cycle.sh qt6-hello-world
```

#### 2. **Quick Deploy** (`auto-deploy.sh`)
Downloads and deploys latest successful build:
```bash
./auto-deploy.sh
```

**What it does:**
1. Finds latest successful GHA build
2. Downloads artifacts
3. Deploys to connected device

#### 3. **Deploy & Monitor** (`deploy-and-monitor.sh`)
Deploy specific IPA and monitor:
```bash
./deploy-and-monitor.sh [IPA_PATH] [BUNDLE_ID] [DEVICE_ID]
```

## Quick Start

### First Time Setup

1. **Set up GitHub Secrets** (already done):
   ```bash
   ./export-cert.sh        # Export your certificate
   ./setup-gh-secrets.sh   # Upload to GitHub
   ```

2. **Connect your iOS device** via USB or WiFi

3. **Run full deployment**:
   ```bash
   ./full-deploy-cycle.sh qt6-hello-world
   ```

### Testing the App

Once deployed, on your iPhone:
1. Look for "Hello World" app icon
2. Tap to launch
3. You should see the GUI with text

If you see "Untrusted Developer":
- Go to **Settings** → **General** → **VPN & Device Management**
- Tap your developer profile
- Tap **Trust**

## Manual Deployment

If you prefer manual steps:

```bash
# 1. Download latest build
gh run download $(gh run list --workflow=ios-build-sign.yml --branch=qt6-hello-world --status=success --limit 1 --json databaseId --jq '.[0].databaseId')

# 2. Deploy to device
ios-deploy --bundle signed-ios-app/HelloWorld.ipa

# 3. Verify
ios-deploy --bundle_id org.kazer.ios-test --exists
```

## App Details

- **Name**: Hello World
- **Bundle ID**: org.kazer.ios-test
- **Size**: ~20KB
- **Min iOS**: 13.0
- **Architecture**: arm64
- **Framework**: UIKit (native iOS)

## Troubleshooting

### Device Not Detected
```bash
# Check device connection
ios-deploy --detect

# For WiFi deployment, ensure device is paired via USB first
```

### App Crashes
```bash
# Check bundle ID matches provisioning profile
plutil -p signed-ios-app/HelloWorld.app/Info.plist | grep CFBundleIdentifier

# Verify signature
codesign -vvv signed-ios-app/HelloWorld.app
```

### Build Fails
```bash
# Check workflow logs
gh run view --log-failed

# Common issues:
# - macOS runners unavailable (retry)
# - Certificate expired (renew)
# - Provisioning profile expired (renew)
```

## Development Workflow

### Make Code Changes

1. **Edit the app** in `ios-app/main.m`
2. **Commit and push**:
   ```bash
   git add ios-app/
   git commit -m "Update iOS app"
   git push
   ```
3. **Deploy**:
   ```bash
   ./full-deploy-cycle.sh qt6-hello-world
   ```

### Branch Structure

- **`main`**: Simple console app (original)
- **`qt6-hello-world`**: Native iOS GUI app

## GitHub Actions Workflow

The workflow (`ios-build-sign.yml`):
1. ✓ Checks out code
2. ✓ Sets up Xcode
3. ✓ Imports certificates to temp keychain
4. ✓ Installs provisioning profile
5. ✓ Builds native iOS app with UIKit
6. ✓ Signs with your certificate
7. ✓ Creates IPA
8. ✓ Uploads as artifact

**Artifacts available for 30 days:**
- `signed-ios-app`: The IPA file
- `build-artifacts`: App bundle and entitlements

## Next Steps

### To add features:
1. Edit `ios-app/main.m`
2. Add UI elements (buttons, labels, etc.)
3. Run `./full-deploy-cycle.sh qt6-hello-world`

### To switch back to simple console app:
```bash
git checkout main
./full-deploy-cycle.sh main
```

## Support

- **Certificate valid until**: April 20, 2026
- **Provisioning profile valid until**: April 20, 2026
- **Team ID**: 4D6V9Q7PN2
- **Developer**: Pierre Grandin
