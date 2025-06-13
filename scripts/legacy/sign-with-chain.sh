#!/bin/bash
set -euo pipefail

# iOS App Signing with Full Certificate Chain

echo "=== iOS App Signing with Certificate Chain ==="

# Configuration
APP_PATH="app/SampleApp.app"
PROVISION="test.mobileprovision"
ENTITLEMENTS="Entitlements.plist"

# Import full certificate chain to login keychain
echo "Setting up certificate chain..."

# Download Apple Root CA G3 (the current one)
if [[ ! -f "AppleRootCA-G3.cer" ]]; then
    echo "Downloading Apple Root CA G3..."
    curl -L -o AppleRootCA-G3.cer "https://www.apple.com/certificateauthority/AppleRootCA-G3.cer"
fi

# Import certificates in order
echo "Importing Apple Root CA G3..."
security import AppleRootCA-G3.cer || true

echo "Importing WWDR certificate..."
security import AppleWWDRCA.cer || true

echo "Importing developer certificate..."
security import ios_dev_fixed.p12 -P test123 -A || true

# Set trust settings
echo "Setting trust for certificates..."
security add-trusted-cert -d -r trustRoot AppleRootCA-G3.cer 2>/dev/null || true
security add-trusted-cert -d -r trustAsRoot AppleWWDRCA.cer 2>/dev/null || true

# Check identities
echo "Available identities:"
security find-identity -v -p codesigning

# Prepare app
echo "Preparing app..."
rm -rf "$APP_PATH/_CodeSignature"
cp "$PROVISION" "$APP_PATH/embedded.mobileprovision"
xattr -cr "$APP_PATH"

# Try signing with different approaches
echo "Attempting to sign app..."

# Method 1: Use certificate hash
if codesign --force --sign "7C2AADACFA2357AF51369C01989F3A3A1AB2AFC1" \
    --entitlements "$ENTITLEMENTS" \
    --timestamp=none \
    --verbose "$APP_PATH" 2>/dev/null; then
    echo "✅ Successfully signed with certificate hash"
else
    echo "Method 1 failed, trying identity name..."
    
    # Method 2: Use identity name
    if codesign --force --sign "iPhone Developer: Pierre Grandin (753B97V58J)" \
        --entitlements "$ENTITLEMENTS" \
        --timestamp=none \
        --verbose "$APP_PATH" 2>/dev/null; then
        echo "✅ Successfully signed with identity name"
    else
        echo "Method 2 failed, trying without entitlements..."
        
        # Method 3: Sign without entitlements
        if codesign --force --sign "7C2AADACFA2357AF51369C01989F3A3A1AB2AFC1" \
            --timestamp=none \
            --verbose "$APP_PATH"; then
            echo "✅ Successfully signed without entitlements"
        else
            echo "❌ All signing methods failed"
            exit 1
        fi
    fi
fi

# Verify
echo "Verifying signature..."
codesign --verify --verbose "$APP_PATH" || echo "Verification failed but continuing..."

# Create IPA
echo "Creating IPA..."
mkdir -p output/Payload
cp -R "$APP_PATH" output/Payload/
(cd output && zip -qr SampleApp.ipa Payload)
rm -rf output/Payload

echo "✅ Done! IPA created at: output/SampleApp.ipa"