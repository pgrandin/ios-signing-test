#!/bin/bash
set -euo pipefail

# Export iOS Certificate and Prepare for GitHub Actions
# This script exports your certificate from Keychain and prepares it for GHA

echo "=== iOS Certificate Export for GitHub Actions ==="
echo

# Configuration
CERT_NAME="iPhone Developer: Pierre Grandin (753B97V58J)"
PROVISION_PROFILE="app.mobileprovision"
OUTPUT_DIR="gha-secrets"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Ask for P12 password
echo "Enter a password for the P12 file (you'll need this for GitHub Secrets):"
read -s P12_PASSWORD
echo
echo "Confirm password:"
read -s P12_PASSWORD_CONFIRM
echo

if [[ "$P12_PASSWORD" != "$P12_PASSWORD_CONFIRM" ]]; then
    echo "❌ Passwords don't match!"
    exit 1
fi

# Export certificate from keychain
echo "Exporting certificate from keychain..."
echo "(You may be prompted for your Mac password)"
security find-certificate -c "$CERT_NAME" -p > "$OUTPUT_DIR/cert.pem"

# Export private key
echo "Exporting private key..."
security find-certificate -c "$CERT_NAME" -a -Z | grep ^SHA-1 | awk '{print $3}' > "$OUTPUT_DIR/cert_hash.txt"
CERT_HASH=$(cat "$OUTPUT_DIR/cert_hash.txt")

# Create P12 with certificate and private key
echo "Creating P12 file..."
security export -k login.keychain-db \
  -t identities \
  -f pkcs12 \
  -P "$P12_PASSWORD" \
  -o "$OUTPUT_DIR/ios-cert.p12" \
  "$CERT_NAME" 2>/dev/null || {
    echo "❌ Failed to export certificate. Make sure you have the private key in your keychain."
    exit 1
}

# Fix P12 format for compatibility
echo "Fixing P12 format..."
# Extract all contents to PEM (use legacy provider for old ciphers)
openssl pkcs12 \
  -in "$OUTPUT_DIR/ios-cert.p12" \
  -passin pass:"$P12_PASSWORD" \
  -out "$OUTPUT_DIR/cert-temp.pem" \
  -nodes \
  -legacy

# Re-export with legacy mode for macOS compatibility
openssl pkcs12 \
  -export \
  -legacy \
  -in "$OUTPUT_DIR/cert-temp.pem" \
  -passout pass:"$P12_PASSWORD" \
  -out "$OUTPUT_DIR/ios-cert-fixed.p12"

# Replace original with fixed version
mv "$OUTPUT_DIR/ios-cert-fixed.p12" "$OUTPUT_DIR/ios-cert.p12"
rm "$OUTPUT_DIR/cert-temp.pem"

# Encode certificate to base64
echo "Encoding certificate to base64..."
cat "$OUTPUT_DIR/ios-cert.p12" | base64 > "$OUTPUT_DIR/cert-base64.txt"

# Encode provisioning profile to base64
echo "Encoding provisioning profile to base64..."
if [[ -f "$PROVISION_PROFILE" ]]; then
    cat "$PROVISION_PROFILE" | base64 > "$OUTPUT_DIR/provision-base64.txt"
else
    echo "⚠️  Warning: $PROVISION_PROFILE not found"
fi

# Create secrets file with instructions
cat > "$OUTPUT_DIR/GITHUB_SECRETS.txt" << EOF
=== GitHub Actions Secrets ===

Add these three secrets to your GitHub repository:
Settings → Secrets and variables → Actions → New repository secret

---

1. Secret Name: IOS_CERTIFICATE_P12_BASE64
   Secret Value:
$(cat "$OUTPUT_DIR/cert-base64.txt")

---

2. Secret Name: IOS_CERTIFICATE_PASSWORD
   Secret Value: $P12_PASSWORD

---

3. Secret Name: IOS_PROVISION_PROFILE_BASE64
   Secret Value:
$(cat "$OUTPUT_DIR/provision-base64.txt")

---

IMPORTANT: Keep this file secure and do not commit it to git!
EOF

# Cleanup temp files
rm -f "$OUTPUT_DIR/cert.pem" "$OUTPUT_DIR/cert_hash.txt"

echo
echo "✅ Success! Files created in $OUTPUT_DIR/"
echo
echo "Generated files:"
echo "  - ios-cert.p12 (your certificate)"
echo "  - cert-base64.txt (base64 encoded certificate)"
echo "  - provision-base64.txt (base64 encoded provisioning profile)"
echo "  - GITHUB_SECRETS.txt (ready to copy/paste into GitHub)"
echo
echo "Next steps:"
echo "1. Open $OUTPUT_DIR/GITHUB_SECRETS.txt"
echo "2. Copy each secret value into GitHub:"
echo "   → Repository → Settings → Secrets and variables → Actions"
echo "3. Delete the $OUTPUT_DIR/ folder after setting up secrets (contains sensitive data)"
echo
echo "Quick view secrets file:"
echo "  cat $OUTPUT_DIR/GITHUB_SECRETS.txt"
