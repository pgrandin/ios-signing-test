#!/bin/bash
set -euo pipefail

# Setup GitHub Secrets using gh CLI
# This script reads the exported secrets and sets them in GitHub

echo "=== Setting up GitHub Secrets ==="
echo

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed"
    echo "Install it with: brew install gh"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub"
    echo "Run: gh auth login"
    exit 1
fi

# Check if secrets directory exists
if [[ ! -d "gha-secrets" ]]; then
    echo "❌ gha-secrets directory not found"
    echo "Run ./export-cert.sh first"
    exit 1
fi

# Read the password from GITHUB_SECRETS.txt
if [[ ! -f "gha-secrets/GITHUB_SECRETS.txt" ]]; then
    echo "❌ GITHUB_SECRETS.txt not found"
    exit 1
fi

# Extract password from GITHUB_SECRETS.txt
P12_PASSWORD=$(grep -A 1 "IOS_CERTIFICATE_PASSWORD" gha-secrets/GITHUB_SECRETS.txt | grep "Secret Value:" | sed 's/^.*Secret Value:[[:space:]]*//')

echo "Enter your GitHub repository (format: owner/repo):"
read -r REPO
echo

echo "Setting secrets for repository: $REPO..."
echo

# Set IOS_CERTIFICATE_P12_BASE64
echo "Setting IOS_CERTIFICATE_P12_BASE64..."
gh secret set IOS_CERTIFICATE_P12_BASE64 --repo "$REPO" < gha-secrets/cert-base64.txt

# Set IOS_CERTIFICATE_PASSWORD
echo "Setting IOS_CERTIFICATE_PASSWORD..."
echo "$P12_PASSWORD" | gh secret set IOS_CERTIFICATE_PASSWORD --repo "$REPO"

# Set IOS_PROVISION_PROFILE_BASE64
echo "Setting IOS_PROVISION_PROFILE_BASE64..."
gh secret set IOS_PROVISION_PROFILE_BASE64 --repo "$REPO" < gha-secrets/provision-base64.txt

echo
echo "✅ All secrets set successfully!"
echo
echo "Verify secrets with:"
echo "  gh secret list"
echo
echo "You can now safely delete the secrets directory:"
echo "  rm -rf gha-secrets/"
