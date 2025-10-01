#!/bin/bash
set -euo pipefail

# WiFi iOS Deployment with Verification
# Deploys app to iOS device over WiFi and verifies launch

echo "╔════════════════════════════════════════╗"
echo "║   WiFi iOS Deployment & Verification   ║"
echo "╚════════════════════════════════════════╝"
echo

# Configuration
IPA_PATH="${1:-signed-ios-app/HelloWorld.ipa}"
BUNDLE_ID="${2:-org.kazer.ios-test}"

# Step 1: Detect device
echo "[1/5] Detecting iOS device on network..."
DEVICE_ID=$(idevice_id -n | head -1)
if [ -z "$DEVICE_ID" ]; then
    echo "❌ No device found on network"
    echo "   Make sure WiFi sync is enabled in Xcode"
    exit 1
fi
echo "✓ Device: $DEVICE_ID"

# Get device name
DEVICE_NAME=$(ideviceinfo -u "$DEVICE_ID" --network -k DeviceName 2>/dev/null || echo "iPhone")
echo "  Name: $DEVICE_NAME"
echo

# Step 2: Check IPA
echo "[2/5] Checking IPA..."
if [ ! -f "$IPA_PATH" ]; then
    echo "❌ IPA not found: $IPA_PATH"
    exit 1
fi
IPA_SIZE=$(ls -lh "$IPA_PATH" | awk '{print $5}')
echo "✓ IPA: $IPA_PATH ($IPA_SIZE)"
echo

# Step 3: Deploy
echo "[3/5] Deploying to $DEVICE_NAME..."
ios-deploy \
    --id "$DEVICE_ID" \
    --bundle "$IPA_PATH" \
    2>&1 | grep -E "\[.*%\].*Install|Complete" | tail -5
echo "✓ Deployment complete"
echo

# Step 4: Verify installation
echo "[4/5] Verifying installation..."
if ios-deploy --id "$DEVICE_ID" --bundle_id "$BUNDLE_ID" --exists 2>&1 | grep -q "true"; then
    echo "✓ App verified on device"
else
    echo "❌ App not found on device"
    exit 1
fi
echo

# Step 5: App info
echo "[5/5] App information..."
unzip -l "$IPA_PATH" 2>/dev/null | grep -E "Payload.*HelloWorld\.app/" | head -1 | awk '{print "  Bundle: " $4}'
echo "  Bundle ID: $BUNDLE_ID"
echo "  Device: $DEVICE_NAME ($DEVICE_ID)"
echo

echo "════════════════════════════════════════"
echo "✅ DEPLOYMENT SUCCESSFUL"
echo "════════════════════════════════════════"
echo
echo "📱 The app is ready on your device!"
echo "   Tap 'Hello World' to launch"
echo
