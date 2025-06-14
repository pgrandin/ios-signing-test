# iOS App Signing Guide

A complete, reproducible solution for signing iOS apps on macOS, with detailed instructions for handling certificates, provisioning profiles, and deployment.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Understanding iOS Code Signing](#understanding-ios-code-signing)
3. [Step-by-Step Setup](#step-by-step-setup)
4. [Signing Process](#signing-process)
5. [Deployment to Device](#deployment-to-device)
6. [Troubleshooting](#troubleshooting)
7. [CI/CD Setup](#cicd-setup)
8. [Advanced Topics](#advanced-topics)

## Prerequisites

- macOS with Xcode Command Line Tools
- Apple Developer account ($99/year)
- iOS device for testing
- USB cable for initial device setup

### Install Required Tools

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Install ios-deploy for device deployment
npm install -g ios-deploy

# Verify installations
security --version
codesign --version
ios-deploy --version
```

## Understanding iOS Code Signing

### Key Components

1. **Certificate**: Proves your identity as a developer
   - Stored in macOS Keychain
   - Contains public/private key pair
   - Types: Development, Distribution

2. **Provisioning Profile**: Links certificate, app ID, and devices
   - Contains list of allowed devices (Development)
   - Specifies app capabilities
   - Must match certificate and bundle ID

3. **Entitlements**: Declares app permissions
   - Camera, network, push notifications, etc.
   - Must match provisioning profile

4. **Bundle ID**: Unique app identifier
   - Format: `com.company.appname`
   - Must match provisioning profile

## Step-by-Step Setup

### 1. Create Apple Developer Account

1. Visit [developer.apple.com](https://developer.apple.com)
2. Enroll in Apple Developer Program ($99/year)
3. Complete enrollment process

### 2. Generate Certificate

#### Option A: Using Xcode (Easiest)
1. Open Xcode → Preferences → Accounts
2. Add your Apple ID
3. Click "Manage Certificates"
4. Click "+" → "iOS Development"

#### Option B: Manual Process
1. Open Keychain Access
2. Certificate Assistant → Request a Certificate
3. Upload to Apple Developer Portal
4. Download and install certificate

### 3. Create Provisioning Profile

1. Log into [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to Certificates, IDs & Profiles
3. Create new App ID:
   - Bundle ID: `com.yourcompany.yourapp`
   - Enable required capabilities
4. Create Provisioning Profile:
   - Select "iOS App Development"
   - Choose your App ID
   - Select your certificate
   - Select test devices
   - Download `.mobileprovision` file

### 4. Register Test Devices

```bash
# Get device UDID
ios-deploy -c

# Or in Xcode
# Window → Devices and Simulators → Select device → Identifier
```

Add UDID to Apple Developer Portal under Devices.

## Signing Process

### Complete Workflow

```bash
# 1. Clone this repository
git clone <this-repo>
cd ios-signing-test

# 2. Copy your provisioning profile
cp ~/Downloads/your_profile.mobileprovision ./app.mobileprovision

# 3. Find your certificate
security find-identity -v -p codesigning
# Output: 1) HASH_HERE "iPhone Developer: Your Name (TEAM_ID)"

# 4. Extract bundle ID from provisioning profile
strings app.mobileprovision | grep -A 1 "application-identifier" | tail -1

# 5. Sign the app
CERT_HASH="YOUR_HASH" PROVISION="app.mobileprovision" ./scripts/sign-ios-app.sh
```

### Manual Signing Process

```bash
# 1. Clean previous signature
rm -rf YourApp.app/_CodeSignature
rm -f YourApp.app/embedded.mobileprovision

# 2. Embed provisioning profile
cp your_profile.mobileprovision YourApp.app/embedded.mobileprovision

# 3. Update bundle ID to match profile
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.yourcompany.app" YourApp.app/Info.plist

# 4. Create entitlements file
cat > entitlements.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>application-identifier</key>
    <string>TEAM_ID.com.yourcompany.app</string>
    <key>com.apple.developer.team-identifier</key>
    <string>TEAM_ID</string>
    <key>get-task-allow</key>
    <true/>
</dict>
</plist>
EOF

# 5. Sign the app
codesign --force --sign "CERT_HASH" \
  --entitlements entitlements.plist \
  --timestamp=none \
  YourApp.app

# 6. Verify signature
codesign -dvv YourApp.app
```

## Deployment to Device

### Automated Deployment

We provide scripts for automated deployment:

```bash
# Deploy signed app to connected device
./deploy-automated.sh

# Deploy with logging
./deploy-with-logs.sh
```

### Manual Deployment

```bash
# 1. Check connected devices
ios-deploy -c

# 2. Deploy to device
ios-deploy --bundle YourApp.app --id DEVICE_ID

# 3. Deploy and launch
ios-deploy --bundle YourApp.app --justlaunch

# 4. Deploy with debug output
ios-deploy --debug --bundle YourApp.app
```

### WiFi Deployment Setup

1. Connect device via USB first
2. Open Xcode → Window → Devices and Simulators
3. Select device → Enable "Connect via network"
4. Disconnect USB cable
5. Deploy over WiFi using same commands

## Troubleshooting

### Certificate Issues

#### "0 valid identities found"
```bash
# Reset keychain search list
security list-keychains -s login.keychain-db System.keychain

# Verify certificate is installed
security find-certificate -c "iPhone Developer"

# Check certificate trust
security verify-cert -c "iPhone Developer"
```

#### "User interaction is not allowed"
```bash
# Unlock keychain
security unlock-keychain login.keychain

# Or allow codesign access
security set-key-partition-list -S apple-tool:,apple: -k "YOUR_PASSWORD" login.keychain
```

### Provisioning Profile Issues

#### "A valid provisioning profile for this executable was not found"
- Ensure device UDID is in the profile
- Bundle ID must match exactly
- Certificate must match profile
- Profile must not be expired

#### Check profile contents
```bash
# Decode and inspect profile
security cms -D -i app.mobileprovision > profile.plist
open profile.plist

# Check expiration
/usr/libexec/PlistBuddy -c "Print :ExpirationDate" profile.plist

# Check devices
/usr/libexec/PlistBuddy -c "Print :ProvisionedDevices" profile.plist
```

### P12 Certificate Issues

#### "MAC verification failed during import"
```bash
# Convert to compatible format
./scripts/fix-p12-format.sh input.p12 password

# Or manually
openssl pkcs12 -in old.p12 -out temp.pem -nodes
openssl pkcs12 -export -in temp.pem -out new.p12
rm temp.pem
```

### Device Trust Issues

1. Unlock device
2. Connect via USB
3. Trust computer when prompted
4. Settings → General → Device Management → Trust Developer

## CI/CD Setup

### GitHub Actions Complete Example

```yaml
name: iOS Build and Sign
on:
  push:
    branches: [main]

jobs:
  build-and-sign:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup certificates
      env:
        P12_BASE64: ${{ secrets.P12_BASE64 }}
        P12_PASSWORD: ${{ secrets.P12_PASSWORD }}
        PROVISION_BASE64: ${{ secrets.PROVISION_BASE64 }}
      run: |
        # Create variables
        CERTIFICATE_PATH=$RUNNER_TEMP/cert.p12
        PP_PATH=$RUNNER_TEMP/profile.mobileprovision
        KEYCHAIN_PATH=$RUNNER_TEMP/app-signing.keychain-db
        
        # Decode files
        echo -n "$P12_BASE64" | base64 --decode -o $CERTIFICATE_PATH
        echo -n "$PROVISION_BASE64" | base64 --decode -o $PP_PATH
        
        # Create keychain
        security create-keychain -p "runner" $KEYCHAIN_PATH
        security set-keychain-settings -lut 21600 $KEYCHAIN_PATH
        security unlock-keychain -p "runner" $KEYCHAIN_PATH
        
        # Import certificate
        security import $CERTIFICATE_PATH -P "$P12_PASSWORD" \
          -A -t cert -f pkcs12 -k $KEYCHAIN_PATH
        security set-key-partition-list -S apple-tool:,apple: \
          -k "runner" $KEYCHAIN_PATH
        security list-keychain -d user -s $KEYCHAIN_PATH
        
        # Copy provisioning profile
        cp $PP_PATH app.mobileprovision
    
    - name: Sign app
      run: |
        CERT_HASH=$(security find-identity -v -p codesigning | grep "iPhone" | awk '{print $2}' | head -1)
        PROVISION="app.mobileprovision" CERT_HASH="$CERT_HASH" ./scripts/sign-ios-app.sh
    
    - name: Upload IPA
      uses: actions/upload-artifact@v4
      with:
        name: app-ipa
        path: output/*.ipa
```

### Prepare Secrets

```bash
# Run preparation script
./scripts/prepare-for-ci.sh

# This will output:
# - P12_BASE64: Your certificate in base64
# - P12_PASSWORD: Certificate password
# - PROVISION_BASE64: Provisioning profile in base64
```

## Advanced Topics

### Multiple Certificates

```bash
# List all certificates
security find-identity -v -p codesigning

# Sign with specific certificate
codesign --force --sign "SPECIFIC_HASH" app.app
```

### App Store Distribution

1. Create Distribution certificate
2. Create App Store provisioning profile
3. Sign without `get-task-allow` entitlement
4. Create IPA for upload

```bash
# Distribution entitlements (no get-task-allow)
cat > dist-entitlements.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>application-identifier</key>
    <string>TEAM_ID.com.yourcompany.app</string>
    <key>com.apple.developer.team-identifier</key>
    <string>TEAM_ID</string>
</dict>
</plist>
EOF
```

### Re-signing Existing Apps

```bash
# Extract existing app
unzip existing.ipa
mv Payload/*.app ./

# Re-sign with your certificate
./scripts/sign-ios-app.sh

# Create new IPA
./scripts/create-ipa.sh YourApp.app
```

### Keychain Management

```bash
# Create dedicated keychain
security create-keychain -p password ios-signing.keychain

# Add to search list
security list-keychains -s ios-signing.keychain

# Import certificate
security import cert.p12 -P "password" -k ios-signing.keychain

# Set as default
security default-keychain -s ios-signing.keychain
```

## Project Structure

```
.
├── README.md                   # This documentation
├── app/                        # Sample apps
│   └── SampleApp.app/         # Basic test app
├── scripts/                    # Automation scripts
│   ├── sign-ios-app.sh        # Main signing script
│   ├── create-ipa.sh          # IPA creation
│   ├── fix-p12-format.sh      # P12 converter
│   └── prepare-for-ci.sh      # CI/CD preparation
├── deploy-automated.sh         # Device deployment
├── deploy-with-logs.sh        # Deployment with logging
├── Entitlements.plist         # Sample entitlements
└── output/                    # Signed apps and IPAs
```

## Quick Reference

```bash
# Find certificate
security find-identity -v -p codesigning

# Sign app
codesign --force --sign "HASH" --entitlements entitlements.plist app.app

# Verify signature
codesign -dvv app.app

# Check provisioning profile
security cms -D -i profile.mobileprovision

# Deploy to device
ios-deploy --bundle app.app --justlaunch

# Create IPA
mkdir Payload && cp -r app.app Payload/
zip -r app.ipa Payload
```

## Contributing

1. Fork the repository
2. Create your feature branch
3. Test thoroughly on real devices
4. Submit a pull request

## License

MIT