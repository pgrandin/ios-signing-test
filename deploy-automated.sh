#!/bin/bash

set -e

echo "=== Automated iOS App Deployment ==="
echo

# Configuration
TEAM_ID="4D6V9Q7PN2"
BUNDLE_ID="com.example.sampleapp"
APP_PATH="app/SampleApp.app"
PROVISION_PATH="app.mobileprovision"
CERT_HASH="7C2AADACFA2357AF51369C01989F3A3A1AB2AFC1"

# Check prerequisites
if ! command -v ios-deploy &> /dev/null; then
    echo "❌ ios-deploy not found. Installing..."
    npm install -g ios-deploy
fi

# Extract actual bundle ID from provisioning profile
echo "📋 Extracting bundle ID from provisioning profile..."
ACTUAL_BUNDLE_ID=$(strings "$PROVISION_PATH" | grep -A 1 "application-identifier" | tail -1 | sed 's/<[^>]*>//g' | sed 's/^[A-Z0-9]*\.//' | tr -d ' \t')
if [ ! -z "$ACTUAL_BUNDLE_ID" ]; then
    echo "   Found bundle ID: $ACTUAL_BUNDLE_ID"
    BUNDLE_ID="$ACTUAL_BUNDLE_ID"
fi

# Clean previous signature
echo "🧹 Cleaning previous signature..."
rm -rf "$APP_PATH/_CodeSignature"
rm -f "$APP_PATH/embedded.mobileprovision"

# Copy provisioning profile
echo "📄 Embedding provisioning profile..."
cp "$PROVISION_PATH" "$APP_PATH/embedded.mobileprovision"

# Update Info.plist with correct bundle ID
echo "📝 Updating bundle identifier..."
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$APP_PATH/Info.plist"

# Create proper entitlements
echo "🔐 Creating entitlements..."
cat > Entitlements-deploy.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>application-identifier</key>
    <string>${TEAM_ID}.${BUNDLE_ID}</string>
    <key>com.apple.developer.team-identifier</key>
    <string>${TEAM_ID}</string>
    <key>get-task-allow</key>
    <true/>
    <key>keychain-access-groups</key>
    <array>
        <string>${TEAM_ID}.*</string>
    </array>
</dict>
</plist>
EOF

# Sign the app
echo "✍️  Signing app..."
codesign --force --sign "$CERT_HASH" \
    --entitlements Entitlements-deploy.plist \
    --timestamp=none \
    "$APP_PATH"

# Verify signature
echo "✅ Verifying signature..."
codesign -dvv "$APP_PATH"

# Check for connected device
echo "📱 Checking for connected devices..."
DEVICE_ID=$(ios-deploy -c --timeout 1 2>&1 | grep -o "[0-9a-f]\{40\}" | head -1)
if [ -z "$DEVICE_ID" ]; then
    # Try with shorter device ID format
    DEVICE_ID=$(ios-deploy -c --timeout 1 2>&1 | grep -oE "[0-9A-F]{8}-[0-9A-F]{16}" | head -1)
fi

if [ -z "$DEVICE_ID" ]; then
    echo "❌ No iOS device found. Please connect your iPhone and trust this computer."
    exit 1
fi

echo "   Found device: $DEVICE_ID"

# Deploy to device
echo "🚀 Deploying to device..."
ios-deploy --id "$DEVICE_ID" --bundle "$APP_PATH" --no-wifi --justlaunch

echo
echo "✅ Deployment complete!"