#!/bin/bash
set -euo pipefail

# iOS App Signing Script
# Signs iOS apps using certificates from your login keychain

echo "=== iOS App Signing ==="

# Configuration
APP_PATH="${APP_PATH:-app/SampleApp.app}"
PROVISION="${PROVISION:-test.mobileprovision}"
ENTITLEMENTS="${ENTITLEMENTS:-Entitlements.plist}"
CERT_HASH="${CERT_HASH:-}"  # Will auto-detect if not provided

# Check and fix keychain list if needed
echo "Checking keychain configuration..."
if security list-keychains | grep -q "Users/daddy/Library/Keychains//Users"; then
    echo "Detected corrupted keychain list, fixing..."
    security list-keychains -s login.keychain-db System.keychain
fi

# Clean up any leftover build keychains
security delete-keychain ios-build.keychain 2>/dev/null || true

# Check for valid identities
echo "Checking codesigning identities..."
IDENTITIES=$(security find-identity -v -p codesigning)
echo "$IDENTITIES"

# Auto-detect certificate if not provided
if [[ -z "$CERT_HASH" ]]; then
    CERT_HASH=$(echo "$IDENTITIES" | grep -E "^[[:space:]]*1\)" | grep -oE "[A-F0-9]{40}" | head -1)
    if [[ -z "$CERT_HASH" ]]; then
        echo "Error: No valid codesigning identity found"
        echo "Please ensure your certificate is in the keychain"
        exit 1
    fi
    echo "Auto-detected certificate: $CERT_HASH"
fi

# Prepare app
echo "Preparing app for signing..."
rm -rf "$APP_PATH/_CodeSignature"
cp "$PROVISION" "$APP_PATH/embedded.mobileprovision"
xattr -cr "$APP_PATH"

# Sign app
echo "Signing app..."
codesign --force \
    --sign "$CERT_HASH" \
    --entitlements "$ENTITLEMENTS" \
    --timestamp=none \
    --verbose \
    "$APP_PATH"

# Verify
echo "Verifying signature..."
codesign --verify --verbose "$APP_PATH"

# Create IPA
echo "Creating IPA..."
mkdir -p output/Payload
cp -R "$APP_PATH" output/Payload/
(cd output && zip -qr SampleApp.ipa Payload)
rm -rf output/Payload

echo "✅ Success! IPA created at: output/SampleApp.ipa"