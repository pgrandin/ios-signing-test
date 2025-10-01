#!/bin/bash
set -e

# Automated Qt6 App Deployment Script
# Downloads latest Qt6 build from GHA and deploys to connected device

BRANCH="qt6-cmake-app"
BUNDLE_ID="org.kazer.ios-test"

echo "═══════════════════════════════════════"
echo "   Qt6 Automated Deployment Pipeline"
echo "═══════════════════════════════════════"
echo

# Step 1: Get latest successful build
echo "[1/5] Finding latest Qt6 build..."
RUN_ID=$(gh run list \
    --workflow=ios-build-sign.yml \
    --branch="$BRANCH" \
    --status=success \
    --limit 1 \
    --json databaseId \
    --jq '.[0].databaseId')

if [ -z "$RUN_ID" ]; then
    echo "❌ No successful Qt6 builds found"
    exit 1
fi

echo "✓ Found build: $RUN_ID"
echo "  URL: https://github.com/pgrandin/ios-signing-test/actions/runs/$RUN_ID"
echo

# Step 2: Download artifacts
echo "[2/5] Downloading Qt6 IPA..."
rm -rf signed-ios-app build-artifacts
gh run download "$RUN_ID" --pattern signed-ios-app

IPA_PATH=$(find signed-ios-app -name "*.ipa" | head -1)
IPA_SIZE=$(ls -lh "$IPA_PATH" | awk '{print $5}')
echo "✓ Downloaded: $IPA_PATH ($IPA_SIZE)"
echo

# Step 3: Check device
echo "[3/5] Detecting device..."
DEVICE_ID=$(idevice_id -n | head -1)
if [ -z "$DEVICE_ID" ]; then
    echo "⚠ No WiFi device, checking USB..."
    DEVICE_ID=$(idevice_id -l | head -1)
fi

if [ -z "$DEVICE_ID" ]; then
    echo "❌ No device found"
    exit 1
fi

DEVICE_NAME=$(ideviceinfo -u "$DEVICE_ID" -k DeviceName 2>/dev/null || echo "iPhone")
echo "✓ Device: $DEVICE_NAME ($DEVICE_ID)"
echo

# Step 4: Deploy
echo "[4/5] Deploying Qt6 app..."
ios-deploy --id "$DEVICE_ID" --bundle "$IPA_PATH" 2>&1 | \
    grep -E "\[.*%\].*Install|Complete" | tail -5
echo "✓ Deployment complete"
echo

# Step 5: Verify
echo "[5/5] Verifying installation..."
if ios-deploy --id "$DEVICE_ID" --bundle_id "$BUNDLE_ID" --exists 2>&1 | grep -q "true"; then
    echo "✓ App verified on device"
else
    echo "❌ Verification failed"
    exit 1
fi
echo

echo "═══════════════════════════════════════"
echo "✅ QT6 DEPLOYMENT COMPLETE"
echo "═══════════════════════════════════════"
echo
echo "📱 Test the Qt6 app:"
echo "   1. Look for 'Hello World' icon on device"
echo "   2. Tap to launch"
echo "   3. You should see:"
echo "      • 'Hello World from Qt6!'"
echo "      • 'Built with GitHub Actions + CMake'"
echo "      • Qt6 QML interface"
echo
echo "App Details:"
echo "  Name: Hello World Qt6"
echo "  Bundle ID: $BUNDLE_ID"
echo "  Size: $IPA_SIZE"
echo "  Framework: Qt 6.8.1 + QML"
echo "  Device: $DEVICE_NAME"
echo
echo "⚠️  If you see 'Untrusted Developer':"
echo "   Settings → General → VPN & Device Management"
echo "   → Pierre Grandin → Trust"
echo
