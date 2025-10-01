# GitHub Actions Setup Guide

You already have the necessary certificates and provisioning profiles! Here's how to set them up for GitHub Actions.

## What You Have

✅ **Certificate**: iPhone Developer: Pierre Grandin (753B97V58J)
- Valid until: April 20, 2026
- Team ID: 4D6V9Q7PN2

✅ **Provisioning Profile**: `app.mobileprovision`
- App ID: `org.kazer.ios-test`
- Valid until: April 20, 2026

## Step 1: Export Your Certificate to P12

You need to export your certificate from Keychain to a P12 file:

### Option A: Using Keychain Access (GUI)

1. Open **Keychain Access** app
2. Select **login** keychain on the left
3. Select **My Certificates** category
4. Find "iPhone Developer: Pierre Grandin (753B97V58J)"
5. Right-click → **Export "iPhone Developer: Pierre Grandin..."**
6. Save as: `ios-cert.p12`
7. Set a password (you'll need this for GitHub Secrets)
8. Enter your Mac password to allow the export

### Option B: Using Command Line

```bash
# Export certificate to P12
security export -k login.keychain-db \
  -t identities \
  -f pkcs12 \
  -P "YOUR_PASSWORD_HERE" \
  -o ios-cert.p12 \
  "iPhone Developer: Pierre Grandin (753B97V58J)"
```

## Step 2: Prepare Files for GitHub (Base64 Encoding)

```bash
# Fix P12 format if needed (for macOS compatibility)
./scripts/fix-p12-format.sh ios-cert.p12 ios-cert-fixed.p12

# Encode certificate to base64
cat ios-cert-fixed.p12 | base64 | pbcopy
# The base64 string is now in your clipboard
# This is the value for IOS_CERTIFICATE_P12_BASE64

# Encode provisioning profile to base64
cat app.mobileprovision | base64 | pbcopy
# The base64 string is now in your clipboard
# This is the value for IOS_PROVISION_PROFILE_BASE64
```

Or use the automated script:

```bash
./scripts/prepare-for-ci.sh ios-cert-fixed.p12 app.mobileprovision
```

## Step 3: Add Secrets to GitHub

1. Go to your repository on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add these three secrets:

### Secret 1: `IOS_CERTIFICATE_P12_BASE64`
- Click "New repository secret"
- Name: `IOS_CERTIFICATE_P12_BASE64`
- Value: Paste the base64 encoded P12 (from Step 2)
- Click "Add secret"

### Secret 2: `IOS_CERTIFICATE_PASSWORD`
- Click "New repository secret"
- Name: `IOS_CERTIFICATE_PASSWORD`
- Value: The password you set when exporting the P12
- Click "Add secret"

### Secret 3: `IOS_PROVISION_PROFILE_BASE64`
- Click "New repository secret"
- Name: `IOS_PROVISION_PROFILE_BASE64`
- Value: Paste the base64 encoded mobileprovision (from Step 2)
- Click "Add secret"

## Step 4: Test the Workflow

1. Commit and push the workflow files:
```bash
git add .github/
git commit -m "Add GitHub Actions workflow for iOS signing"
git push
```

2. Go to **Actions** tab in your GitHub repository
3. You should see the "Build and Sign iOS App" workflow running
4. Wait for it to complete
5. Download the signed IPA from the artifacts section

## Troubleshooting

### Certificate Export Fails
- Make sure you're exporting from the **login** keychain
- The certificate should show with a private key (triangle/arrow to expand it)
- You need both the certificate AND the private key

### "No identity found" Error
- Ensure you exported the certificate with its private key
- The P12 file should be larger than 1KB (usually 2-4KB)

### Need to Re-export Certificate?
If you don't have access to the private key in your keychain, you'll need to:
1. Generate a new Certificate Signing Request (CSR)
2. Create a new certificate in Apple Developer Portal
3. Download and install the new certificate
4. Create a new provisioning profile with the new certificate

## Quick Reference

**Your Details:**
- Team ID: `4D6V9Q7PN2`
- Bundle ID: `org.kazer.ios-test`
- Certificate: Valid until April 20, 2026
- Profile: Valid until April 20, 2026
