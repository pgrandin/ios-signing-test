#!/bin/bash
set -euo pipefail

# Script to prepare certificates for CI/CD
# Encodes certificates to base64 for GitHub Secrets

echo "iOS CI/CD Certificate Preparation"
echo "================================="
echo
echo "This script will encode your certificates to base64 format"
echo "for use with GitHub Actions secrets."
echo

# Function to encode file and display instructions
encode_file() {
    local file_path="$1"
    local secret_name="$2"
    
    if [[ ! -f "$file_path" ]]; then
        echo "❌ File not found: $file_path"
        return 1
    fi
    
    echo "📄 Encoding: $file_path"
    echo "GitHub Secret Name: $secret_name"
    echo "---"
    base64 < "$file_path"
    echo "---"
    echo
}

# Encode certificates
echo "🔐 P12 Certificate (ios_dev.p12):"
encode_file "ios_dev.p12" "P12_BASE64"

echo "📋 Provisioning Profile (test.mobileprovision):"
encode_file "test.mobileprovision" "PROVISION_BASE64"

echo "🏢 WWDR Certificate (AppleWWDRCA.cer):"
encode_file "AppleWWDRCA.cer" "WWDR_BASE64"

# Get certificate hash
if [[ -f "ios_dev.p12" ]]; then
    echo "🔍 Certificate Hash:"
    echo "To get your certificate hash, import the P12 and run:"
    echo "security find-identity -p codesigning -v"
    echo
fi

# Instructions
echo "📝 GitHub Actions Setup Instructions:"
echo "1. Go to your GitHub repository settings"
echo "2. Navigate to Secrets and variables > Actions"
echo "3. Add the following secrets:"
echo "   - P12_BASE64: (encoded content above)"
echo "   - PROVISION_BASE64: (encoded content above)"
echo "   - WWDR_BASE64: (encoded content above)"
echo "   - P12_PASSWORD: Your P12 password"
echo "   - CERTIFICATE_HASH: Your certificate SHA-1 hash"
echo "   - KEYCHAIN_PASSWORD: Any secure password for the temp keychain"
echo
echo "✅ Setup complete!"