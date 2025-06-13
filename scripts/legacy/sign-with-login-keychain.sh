#!/bin/bash
set -euo pipefail

# iOS App Signing using Login Keychain
# This script uses certificates from the login keychain

echo "=== iOS App Signing (Login Keychain) ==="

# Configuration
APP_PATH="app/SampleApp.app"
PROVISION="test.mobileprovision"
ENTITLEMENTS="Entitlements.plist"
IDENTITY="iPhone Developer: Pierre Grandin (753B97V58J)"

# Check available identities
echo "Checking available identities in login keychain..."
security find-identity -v -p codesigning

# Prepare app
echo "Preparing app..."
rm -rf "$APP_PATH/_CodeSignature"
cp "$PROVISION" "$APP_PATH/embedded.mobileprovision"
xattr -cr "$APP_PATH"

# Sign app using login keychain
echo "Signing app with identity: $IDENTITY"
codesign --force --sign "$IDENTITY" \
  --entitlements "$ENTITLEMENTS" \
  --timestamp=none \
  --verbose "$APP_PATH"

# Verify
echo "Verifying signature..."
codesign --verify --verbose "$APP_PATH"

# Create IPA
echo "Creating IPA..."
mkdir -p output/Payload
cp -R "$APP_PATH" output/Payload/
(cd output && zip -qr SampleApp.ipa Payload)
rm -rf output/Payload

echo "✅ Done! IPA created at: output/SampleApp.ipa"