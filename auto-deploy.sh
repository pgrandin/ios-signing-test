#!/bin/bash
set -euo pipefail

# Fully Automated iOS Deployment
# Downloads latest build from GHA and deploys to connected device

echo "=== Automated iOS Deployment ==="
echo

# Get latest successful workflow run
echo "Finding latest successful build..."
RUN_ID=$(gh run list \
    --workflow=ios-build-sign.yml \
    --branch=qt6-hello-world \
    --status=success \
    --limit 1 \
    --json databaseId \
    --jq '.[0].databaseId')

if [ -z "$RUN_ID" ]; then
    echo "❌ No successful builds found"
    exit 1
fi

echo "✓ Found build: $RUN_ID"
echo

# Download artifacts
echo "Downloading artifacts..."
rm -rf signed-ios-app build-artifacts
gh run download "$RUN_ID" -R pgrandin/ios-signing-test
echo "✓ Downloaded"
echo

# Get IPA info
IPA_PATH=$(find signed-ios-app -name "*.ipa" | head -1)
IPA_SIZE=$(ls -lh "$IPA_PATH" | awk '{print $5}')
echo "IPA: $IPA_PATH ($IPA_SIZE)"
echo

# Check device
echo "Detecting device..."
DEVICE_INFO=$(ios-deploy --detect --timeout 5 2>&1 | grep "Using" | head -1 || echo "")
if [ -z "$DEVICE_INFO" ]; then
    echo "❌ No device detected. Please connect your iOS device."
    exit 1
fi
echo "✓ $DEVICE_INFO"
echo

# Uninstall old version first
echo "Uninstalling old version..."
ios-deploy \
    --bundle_id org.kazer.ios-test \
    --uninstall_only \
    --no-wifi 2>&1 | grep -v "Unable to locate" || true
echo

# Install new version
echo "Installing app..."
ios-deploy \
    --bundle "$IPA_PATH" \
    --no-wifi \
    --noninteractive 2>&1 | \
    grep -E "\[.*%\]|Install|Complete" | \
    tail -20

echo
echo "✅ Deployment complete!"
echo
echo "The app is now installed on your device."
echo "Tap the 'Hello World' icon to launch it."
echo
echo "App details:"
unzip -l "$IPA_PATH" | grep -E "Payload.*\.app" | head -1
