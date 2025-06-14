# iOS Code Signing - Technical Deep Dive

This document provides detailed technical information about iOS code signing, certificate management, and common issues.

## Table of Contents

1. [Certificate Types and Management](#certificate-types-and-management)
2. [Keychain Operations](#keychain-operations)
3. [Provisioning Profile Internals](#provisioning-profile-internals)
4. [Entitlements Explained](#entitlements-explained)
5. [Common Errors and Solutions](#common-errors-and-solutions)
6. [Script Documentation](#script-documentation)

## Certificate Types and Management

### Certificate Types

1. **iOS Development Certificate**
   - For testing on physical devices
   - Valid for 1 year
   - Can install on unlimited test devices (with valid provisioning profile)

2. **iOS Distribution Certificate**
   - For App Store and Ad Hoc distribution
   - Valid for 1 year
   - Cannot be used for debugging

### Creating Certificates from Scratch

```bash
# 1. Generate private key
openssl genrsa -out ios_development.key 2048

# 2. Create certificate signing request
openssl req -new -key ios_development.key -out ios_development.csr \
  -subj "/emailAddress=your@email.com/CN=Your Name/C=US"

# 3. Upload CSR to Apple Developer Portal
# Download the certificate as ios_development.cer

# 4. Convert to P12 format
openssl x509 -in ios_development.cer -inform DER -out ios_development.pem
openssl pkcs12 -export -out ios_development.p12 \
  -inkey ios_development.key -in ios_development.pem \
  -password pass:yourpassword
```

### Certificate Storage in Keychain

```bash
# Import certificate
security import ios_development.p12 -P "yourpassword" -T /usr/bin/codesign

# Find certificate hash
security find-identity -v -p codesigning | grep "iPhone Developer"

# Export certificate from keychain
security export -k login.keychain -t identities -f pkcs12 -o exported.p12
```

## Keychain Operations

### Keychain Management

```bash
# List all keychains
security list-keychains

# Create new keychain
security create-keychain -p password signing.keychain

# Add keychain to search list
security list-keychains -s login.keychain signing.keychain

# Unlock keychain
security unlock-keychain -p password signing.keychain

# Lock keychain
security lock-keychain signing.keychain

# Delete keychain
security delete-keychain signing.keychain
```

### Keychain Access Control

```bash
# Allow codesign to access keychain without prompting
security set-key-partition-list -S apple-tool:,apple: -k "password" signing.keychain

# Import with specific access control
security import cert.p12 -P "password" -T /usr/bin/codesign -T /usr/bin/security

# Show keychain info
security show-keychain-info signing.keychain
```

## Provisioning Profile Internals

### Profile Structure

A provisioning profile is a signed plist containing:

```xml
<dict>
    <key>AppIDName</key>
    <string>Your App Name</string>
    
    <key>ApplicationIdentifierPrefix</key>
    <array>
        <string>TEAM_ID</string>
    </array>
    
    <key>CreationDate</key>
    <date>2024-01-01T00:00:00Z</date>
    
    <key>ExpirationDate</key>
    <date>2025-01-01T00:00:00Z</date>
    
    <key>Entitlements</key>
    <dict>
        <!-- App capabilities -->
    </dict>
    
    <key>ProvisionedDevices</key>
    <array>
        <string>DEVICE_UDID_1</string>
        <string>DEVICE_UDID_2</string>
    </array>
    
    <key>TeamIdentifier</key>
    <array>
        <string>TEAM_ID</string>
    </array>
</dict>
```

### Extracting Profile Information

```bash
# Decode profile
security cms -D -i profile.mobileprovision > profile.plist

# Get specific values
/usr/libexec/PlistBuddy -c "Print :TeamIdentifier:0" profile.plist
/usr/libexec/PlistBuddy -c "Print :ExpirationDate" profile.plist
/usr/libexec/PlistBuddy -c "Print :ProvisionedDevices" profile.plist

# Check if profile contains specific device
strings profile.mobileprovision | grep "DEVICE_UDID"

# Extract bundle ID
strings profile.mobileprovision | grep -A1 "application-identifier" | tail -1
```

## Entitlements Explained

### Basic Development Entitlements

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Required for all apps -->
    <key>application-identifier</key>
    <string>TEAM_ID.com.company.app</string>
    
    <key>com.apple.developer.team-identifier</key>
    <string>TEAM_ID</string>
    
    <!-- Allow debugging (development only) -->
    <key>get-task-allow</key>
    <true/>
    
    <!-- Keychain access -->
    <key>keychain-access-groups</key>
    <array>
        <string>TEAM_ID.*</string>
    </array>
</dict>
</plist>
```

### Common Capabilities

```xml
<!-- Push Notifications -->
<key>aps-environment</key>
<string>development</string>

<!-- App Groups -->
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.company.app</string>
</array>

<!-- Associated Domains -->
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:example.com</string>
</array>

<!-- iCloud -->
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudDocuments</string>
    <string>CloudKit</string>
</array>
```

## Common Errors and Solutions

### Error: errSecInternalComponent

**Cause**: Keychain corruption or access issues

**Solutions**:
```bash
# Solution 1: Reset keychain search list
security list-keychains -s login.keychain-db System.keychain

# Solution 2: Recreate keychain
mv ~/Library/Keychains/login.keychain-db ~/Library/Keychains/login.keychain-db.backup
# Restart Mac, keychain will be recreated

# Solution 3: Reset keychain access
security set-key-partition-list -S apple-tool:,apple: -k "" login.keychain
```

### Error: "User interaction is not allowed"

**Cause**: Keychain is locked or codesign doesn't have access

**Solutions**:
```bash
# Unlock keychain
security unlock-keychain login.keychain

# Grant access to codesign
security import cert.p12 -P "password" -T /usr/bin/codesign -A
```

### Error: "MAC verification failed"

**Cause**: P12 file uses newer encryption not supported by macOS

**Solution**:
```bash
# Convert P12 to compatible format
openssl pkcs12 -in old.p12 -out temp.pem -nodes -passin pass:oldpass
openssl pkcs12 -export -in temp.pem -out new.p12 -passout pass:newpass -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES
rm temp.pem
```

### Error: "A valid provisioning profile for this executable was not found"

**Debugging steps**:
```bash
# 1. Check app bundle ID
/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" YourApp.app/Info.plist

# 2. Check profile bundle ID
security cms -D -i profile.mobileprovision | grep -A1 "application-identifier"

# 3. Check if device is in profile
security cms -D -i profile.mobileprovision | grep "ProvisionedDevices" -A 50

# 4. Check certificate matches
codesign -dvv YourApp.app | grep "TeamIdentifier"
security cms -D -i profile.mobileprovision | grep "TeamIdentifier"

# 5. Check profile expiration
security cms -D -i profile.mobileprovision | grep "ExpirationDate"
```

## Script Documentation

### sign-ios-app.sh

Main signing script that handles the complete signing process.

**Environment Variables**:
- `CERT_HASH`: Certificate SHA-1 hash (required)
- `PROVISION`: Path to provisioning profile (default: app.mobileprovision)
- `APP_PATH`: Path to app bundle (default: app/SampleApp.app)
- `OUTPUT_DIR`: Output directory (default: output)

**Usage**:
```bash
CERT_HASH="ABC123..." PROVISION="profile.mobileprovision" ./scripts/sign-ios-app.sh
```

**What it does**:
1. Validates keychain configuration
2. Verifies certificate availability
3. Cleans previous signatures
4. Embeds provisioning profile
5. Updates bundle ID from profile
6. Signs with proper entitlements
7. Verifies signature
8. Creates IPA file

### create-ipa.sh

Creates an IPA file from a signed app bundle.

**Usage**:
```bash
./scripts/create-ipa.sh YourApp.app [output.ipa]
```

**Process**:
1. Creates Payload directory
2. Copies app bundle
3. Zips into IPA format
4. Cleans up temporary files

### fix-p12-format.sh

Converts P12 files to a format compatible with older macOS versions.

**Usage**:
```bash
./scripts/fix-p12-format.sh input.p12 password [output.p12]
```

**Why needed**:
- Newer P12 files use AES-256-CBC encryption
- Older macOS versions only support 3DES
- This script converts between formats

### prepare-for-ci.sh

Prepares certificates and profiles for CI/CD environments.

**Usage**:
```bash
./scripts/prepare-for-ci.sh
```

**Output**:
- Base64 encoded P12 certificate
- Base64 encoded provisioning profile
- Instructions for setting up CI secrets

## Advanced Signing Scenarios

### Signing with Multiple Certificates

```bash
# List all certificates
security find-identity -v -p codesigning

# Sign with specific certificate by name
codesign --force --sign "iPhone Developer: John Doe (ABCD1234)" app.app

# Sign with certificate from specific keychain
codesign --force --sign "ABC123" --keychain ~/Library/Keychains/custom.keychain app.app
```

### Re-signing with Different Team

```bash
# Remove old signature completely
rm -rf YourApp.app/_CodeSignature
rm -f YourApp.app/embedded.mobileprovision

# Remove old team references
/usr/libexec/PlistBuddy -c "Delete :AppIdentifierPrefix" YourApp.app/Info.plist 2>/dev/null || true

# Sign with new team
codesign --force --sign "NEW_CERT_HASH" \
  --entitlements new-entitlements.plist \
  --deep --timestamp=none \
  YourApp.app
```

### Signing Frameworks and Nested Code

```bash
# Sign all frameworks first
find YourApp.app -name "*.framework" -exec codesign --force --sign "CERT_HASH" {} \;

# Sign dylibs
find YourApp.app -name "*.dylib" -exec codesign --force --sign "CERT_HASH" {} \;

# Sign the main app
codesign --force --sign "CERT_HASH" --entitlements entitlements.plist YourApp.app
```

## Verification Commands

```bash
# Verify signature
codesign -vvvv YourApp.app

# Check signature details
codesign -dvvv YourApp.app

# Verify against specific requirements
codesign -v --verify-requirement="identifier \"com.company.app\" and certificate leaf[subject.CN] = \"iPhone Developer: Your Name\"" YourApp.app

# Check entitlements
codesign -d --entitlements - YourApp.app

# Verify app will run
spctl --assess --type execute YourApp.app
```

## Security Best Practices

1. **Never commit certificates or profiles to git**
   ```bash
   echo "*.p12" >> .gitignore
   echo "*.mobileprovision" >> .gitignore
   echo "*.cer" >> .gitignore
   ```

2. **Use separate keychains for CI/CD**
   ```bash
   security create-keychain -p "$CI_KEYCHAIN_PWD" ci-signing.keychain
   ```

3. **Rotate certificates annually**
   - Set calendar reminders
   - Keep old certificates for supporting older app versions

4. **Protect private keys**
   - Use strong passwords
   - Store backups in secure location
   - Never share private keys

5. **Audit certificate usage**
   ```bash
   # List all code signing certificates
   security find-identity -v -p codesigning
   
   # Check certificate expiration
   security find-certificate -a -p -c "iPhone" | openssl x509 -noout -enddate
   ```