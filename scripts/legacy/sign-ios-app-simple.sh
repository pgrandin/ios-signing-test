#!/bin/bash
set -euo pipefail

# Simple iOS App Signing Script
# Uses known certificate hash directly

echo "=== Simple iOS App Signing ==="

# Configuration
APP_PATH="app/SampleApp.app"
PROVISION="test.mobileprovision"
ENTITLEMENTS="Entitlements.plist"
P12_PATH="ios_dev_fixed.p12"
P12_PASSWORD="test123"
CERT_HASH="7C2AADACFA2357AF51369C01989F3A3A1AB2AFC1"
KEYCHAIN_NAME="ios-build.keychain"
KEYCHAIN_PASSWORD="temporarypassword"

# Create keychain
echo "Creating keychain..."
security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME"
security list-keychains -d user -s "$KEYCHAIN_NAME" $(security list-keychains -d user | sed 's/"//g')
security default-keychain -s "$KEYCHAIN_NAME"
security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME"

# Import certificates
echo "Importing certificates..."
security import "AppleRootCA.cer" -k "$KEYCHAIN_NAME" -T /usr/bin/codesign
security import "AppleWWDRCA.cer" -k "$KEYCHAIN_NAME" -T /usr/bin/codesign
security import "$P12_PATH" -k "$KEYCHAIN_NAME" -P "$P12_PASSWORD" -T /usr/bin/codesign -A

# Set keychain access
security set-keychain-settings -t 3600 -l "$KEYCHAIN_NAME"
security set-key-partition-list -S apple-tool:,apple: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME"

# Prepare app
echo "Preparing app..."
rm -rf "$APP_PATH/_CodeSignature"
cp "$PROVISION" "$APP_PATH/embedded.mobileprovision"
xattr -cr "$APP_PATH"

# Sign app
echo "Signing app..."
# First check what identities are available
echo "Available identities:"
security find-identity -v -p codesigning "$KEYCHAIN_NAME" || echo "No codesigning identities found"

# Try signing with certificate hash and ignore chain validation
# Use the hash directly and add flags to work around chain issues
codesign --force --sign "$CERT_HASH" \
  --entitlements "$ENTITLEMENTS" \
  --timestamp=none \
  --generate-entitlement-der \
  --deep \
  --verbose "$APP_PATH" || {
    echo "Signing failed, trying alternate method..."
    # If that fails, try without entitlements
    codesign --force --sign "$CERT_HASH" \
      --timestamp=none \
      --deep \
      --verbose "$APP_PATH"
  }

# Verify
echo "Verifying signature..."
codesign --verify --verbose "$APP_PATH"

# Create IPA
echo "Creating IPA..."
mkdir -p output/Payload
cp -R "$APP_PATH" output/Payload/
(cd output && zip -qr SampleApp.ipa Payload)
rm -rf output/Payload

# Cleanup
echo "Cleaning up..."
security delete-keychain "$KEYCHAIN_NAME"

echo "✅ Done! IPA created at: output/SampleApp.ipa"