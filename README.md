# iOS App Signing Guide

A clean, working solution for signing iOS apps on macOS, with support for both local development and CI/CD environments.

## Prerequisites

- macOS with Xcode Command Line Tools
- Apple Developer account with valid iOS Development certificate
- Provisioning profile for your app
- Your certificate must be in your macOS keychain (for local signing)

## Quick Start

### 1. Clone and Setup

```bash
git clone <this-repo>
cd ios-signing-reproduction
```

### 2. Add Your Provisioning Profile

Place your `.mobileprovision` file in the project root:
```bash
cp ~/Downloads/your_app.mobileprovision ./app.mobileprovision
```

### 3. Find Your Certificate

```bash
security find-identity -v -p codesigning
```

You should see something like:
```
1) ABC123... "iPhone Developer: Your Name (XXXXXXXXXX)"
```

Copy the hash (ABC123...) - you'll need it.

### 4. Sign Your App

#### Option A: Use the provided script (recommended)
```bash
CERT_HASH="YOUR_HASH_HERE" PROVISION="app.mobileprovision" ./scripts/sign-ios-app.sh
```

#### Option B: Direct command
```bash
codesign --force --sign "YOUR_HASH_HERE" \
  --entitlements Entitlements.plist \
  --timestamp=none \
  app/SampleApp.app
```

### 5. Create IPA (optional)

```bash
./scripts/create-ipa.sh app/SampleApp.app
```

## Troubleshooting

### "0 valid identities found"

Your keychain list might be corrupted. Fix it:

```bash
security list-keychains -s login.keychain-db System.keychain
```

Then check again:
```bash
security find-identity -v -p codesigning
```

### "errSecInternalComponent"

This usually means:
1. Keychain access issues (see above)
2. Certificate not trusted
3. Provisioning profile doesn't match certificate

### P12 Import Issues

If importing a P12 file fails with "MAC verification failed":

```bash
./scripts/fix-p12-format.sh your_cert.p12 your_password
```

This converts the P12 to a format macOS can read.

## CI/CD Setup

For GitHub Actions or other CI environments where you need to import certificates:

### 1. Prepare Your Certificates

```bash
./scripts/prepare-for-ci.sh
```

This will:
- Convert your P12 to the correct format
- Generate base64 encodings
- Show you what secrets to add to GitHub

### 2. GitHub Actions

Use the provided workflow:
```yaml
name: Sign iOS App
on: push

jobs:
  sign:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - name: Sign App
        env:
          P12_BASE64: ${{ secrets.P12_BASE64 }}
          P12_PASSWORD: ${{ secrets.P12_PASSWORD }}
          PROVISION_BASE64: ${{ secrets.PROVISION_BASE64 }}
        run: |
          # Decode certificates
          echo "$P12_BASE64" | base64 --decode > cert.p12
          echo "$PROVISION_BASE64" | base64 --decode > app.mobileprovision
          
          # Create keychain
          security create-keychain -p temp build.keychain
          security default-keychain -s build.keychain
          security unlock-keychain -p temp build.keychain
          
          # Import certificate
          security import cert.p12 -P "$P12_PASSWORD" -A
          
          # Sign
          ./scripts/sign-ios-app.sh
```

## Project Structure

```
.
├── app/                    # Sample iOS app
│   └── SampleApp.app/      # Pre-built ARM64 executable
├── scripts/                
│   ├── sign-ios-app.sh     # Main signing script
│   ├── create-ipa.sh       # IPA packaging script
│   ├── fix-p12-format.sh   # P12 format converter
│   └── prepare-for-ci.sh   # CI/CD preparation
├── Entitlements.plist      # iOS app entitlements
└── output/                 # Signed apps go here
```

## How It Works

1. **Certificate Lookup**: Find your signing identity in the keychain
2. **App Preparation**: Remove old signatures, add provisioning profile
3. **Code Signing**: Apply signature with entitlements
4. **Verification**: Ensure signature is valid
5. **Packaging**: Create IPA for distribution (optional)

## Common Use Cases

### Sign with specific certificate
```bash
CERT_HASH="ABC123..." ./scripts/sign-ios-app.sh
```

### Sign with custom app path
```bash
APP_PATH="/path/to/MyApp.app" ./scripts/sign-ios-app.sh
```

### Sign multiple apps
```bash
for app in *.app; do
  APP_PATH="$app" ./scripts/sign-ios-app.sh
done
```

## Notes

- The sample app is a simple ARM64 executable that prints "Sample iOS App"
- Entitlements.plist includes basic permissions (adjust as needed)
- Provisioning profiles must match your certificate and app ID
- For App Store distribution, you'll need a distribution certificate

## License

MIT