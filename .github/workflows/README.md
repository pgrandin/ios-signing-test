# GitHub Actions Workflow Setup

This directory contains GitHub Actions workflows for building and signing iOS applications.

## Workflow: Build and Sign iOS App

The `ios-build-sign.yml` workflow automates the complete iOS build and signing process:

1. Compiles the iOS app from source (`app/main.c`)
2. Creates a proper iOS app bundle
3. Signs the app with your development certificate
4. Creates an IPA file ready for testing
5. Uploads the signed IPA as a build artifact

## Required GitHub Secrets

To use this workflow, you need to configure the following secrets in your GitHub repository:

### 1. `IOS_CERTIFICATE_P12_BASE64`

Your iOS development certificate in P12 format, encoded as base64.

**How to create:**
```bash
# If you need to fix P12 format first (macOS compatibility)
./scripts/fix-p12-format.sh your-cert.p12 fixed-cert.p12

# Encode to base64
cat fixed-cert.p12 | base64 | pbcopy
```

Then add this to GitHub:
1. Go to your repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `IOS_CERTIFICATE_P12_BASE64`
4. Value: Paste the base64 string
5. Click "Add secret"

### 2. `IOS_CERTIFICATE_PASSWORD`

The password for your P12 certificate.

**How to add:**
1. Go to your repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `IOS_CERTIFICATE_PASSWORD`
4. Value: Your certificate password
5. Click "Add secret"

### 3. `IOS_PROVISION_PROFILE_BASE64`

Your iOS provisioning profile encoded as base64.

**How to create:**
```bash
# Encode your provisioning profile
cat your.mobileprovision | base64 | pbcopy
```

Then add this to GitHub:
1. Go to your repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `IOS_PROVISION_PROFILE_BASE64`
4. Value: Paste the base64 string
5. Click "Add secret"

## Quick Setup Script

You can use the existing script to prepare your certificates:

```bash
./scripts/prepare-for-ci.sh your-cert.p12 your.mobileprovision
```

This will output:
- Base64 encoded certificate (for `IOS_CERTIFICATE_P12_BASE64`)
- Base64 encoded provisioning profile (for `IOS_PROVISION_PROFILE_BASE64`)

## Triggering the Workflow

The workflow runs automatically on:
- Push to `main` or `develop` branches
- Pull requests to `main` branch
- Manual trigger (workflow_dispatch)

To manually trigger:
1. Go to your repository → Actions
2. Select "Build and Sign iOS App" workflow
3. Click "Run workflow"

## Downloading the Signed IPA

After the workflow completes:
1. Go to the workflow run page
2. Scroll down to "Artifacts"
3. Download `signed-ios-app.zip`
4. Extract to get `SampleApp.ipa`

## Troubleshooting

### Certificate Import Fails

- Ensure your P12 is in the correct format (use `fix-p12-format.sh`)
- Verify the password is correct
- Check that the certificate is valid and not expired

### Signing Identity Not Found

- Verify the certificate was imported successfully
- Check the keychain setup logs in the workflow output
- Ensure the certificate type matches (Development vs Distribution)

### Bundle ID Mismatch

The workflow automatically extracts the bundle ID from your provisioning profile, but verify:
- Your provisioning profile is valid
- The App ID in the profile matches your app
- The certificate matches the provisioning profile type

### Provisioning Profile Issues

- Ensure the provisioning profile is not expired
- Verify it includes the device UDIDs you're testing on (for Development profiles)
- Check that the certificate used to sign matches the profile

## Testing the Signed App

Once you download the IPA:

```bash
# Install on connected device
ios-deploy --bundle output/SampleApp.ipa

# Or use Xcode
# Device → Window → Devices and Simulators → [Your Device] → Installed Apps → + → Select IPA
```

## Security Notes

- Never commit P12 files or provisioning profiles directly to the repository
- Always use GitHub Secrets for sensitive data
- The workflow creates a temporary keychain that is deleted after the build
- Secrets are never exposed in workflow logs
