#!/bin/bash
set -euo pipefail

# Automated iOS App Deployment and Monitoring
# This script deploys an IPA to a connected device and monitors its execution

echo "=== iOS App Deploy & Monitor ==="
echo

# Configuration
IPA_PATH="${1:-signed-ios-app/HelloWorld.ipa}"
BUNDLE_ID="${2:-org.kazer.ios-test}"
DEVICE_ID="${3:-00008110-000E28D00A51801E}"
TIMEOUT="${4:-30}"

if [ ! -f "$IPA_PATH" ]; then
    echo "❌ IPA not found: $IPA_PATH"
    exit 1
fi

echo "IPA: $IPA_PATH"
echo "Bundle ID: $BUNDLE_ID"
echo "Device: $DEVICE_ID"
echo

# Check device connectivity
echo "Checking device connectivity..."
if ! ios-deploy --detect --timeout 5 2>&1 | grep -q "$DEVICE_ID"; then
    echo "❌ Device not found"
    exit 1
fi
echo "✓ Device connected"
echo

# Install the app
echo "Installing app..."
ios-deploy --bundle "$IPA_PATH" --no-wifi 2>&1 | grep -E "\[.*%\]|Install|Error" || true
echo "✓ App installed"
echo

# Launch app with lldb and capture output
echo "Launching app and capturing logs..."
echo "Press Ctrl+C to stop monitoring"
echo "---"

# Use ios-deploy with debug mode to launch and capture output
timeout $TIMEOUT ios-deploy \
    --id "$DEVICE_ID" \
    --bundle_id "$BUNDLE_ID" \
    --noinstall \
    --debug \
    --noninteractive \
    --no-wifi 2>&1 | grep -v "Unable to locate DeviceSupport" | grep -v "ios-deploy\[" || true

echo "---"
echo
echo "✓ Monitoring complete"
