#!/bin/bash
set -euo pipefail

# iOS App Signing Script
# Designed for both local development and CI/CD environments
# Version: 1.0.0

# Default configuration
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
readonly APP_PATH="${APP_PATH:-$PROJECT_ROOT/app/SampleApp.app}"
readonly OUTPUT_DIR="${OUTPUT_DIR:-$PROJECT_ROOT/output}"

# Certificate and signing configuration
readonly P12_PATH="${P12_PATH:-$PROJECT_ROOT/ios_dev_fixed.p12}"
readonly P12_PASSWORD="${P12_PASSWORD:-test123}"
readonly PROVISION_PATH="${PROVISION_PATH:-$PROJECT_ROOT/test.mobileprovision}"
readonly ENTITLEMENTS_PATH="${ENTITLEMENTS_PATH:-$PROJECT_ROOT/Entitlements.plist}"
readonly WWDR_CERT_PATH="${WWDR_CERT_PATH:-$PROJECT_ROOT/AppleWWDRCA.cer}"

# Keychain configuration
readonly KEYCHAIN_NAME="${KEYCHAIN_NAME:-ios-build.keychain}"
readonly KEYCHAIN_PASSWORD="${KEYCHAIN_PASSWORD:-temporarypassword}"
readonly CERTIFICATE_HASH="${CERTIFICATE_HASH:-}"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_step() {
    echo -e "\n${GREEN}==>${NC} $1"
}

# Error handling
handle_error() {
    log_error "An error occurred on line $1"
    cleanup_on_error
    exit 1
}

trap 'handle_error $LINENO' ERR

# Cleanup function
cleanup_on_error() {
    log_warn "Cleaning up after error..."
    if security list-keychains | grep -q "$KEYCHAIN_NAME"; then
        security delete-keychain "$KEYCHAIN_NAME" 2>/dev/null || true
    fi
}

# Validate required files
validate_prerequisites() {
    log_step "Validating prerequisites"
    
    local missing_files=()
    
    [[ ! -f "$P12_PATH" ]] && missing_files+=("P12 certificate: $P12_PATH")
    [[ ! -f "$PROVISION_PATH" ]] && missing_files+=("Provisioning profile: $PROVISION_PATH")
    [[ ! -f "$ENTITLEMENTS_PATH" ]] && missing_files+=("Entitlements: $ENTITLEMENTS_PATH")
    [[ ! -f "$WWDR_CERT_PATH" ]] && missing_files+=("WWDR certificate: $WWDR_CERT_PATH")
    [[ ! -d "$APP_PATH" ]] && missing_files+=("App bundle: $APP_PATH")
    
    if [[ ${#missing_files[@]} -gt 0 ]]; then
        log_error "Missing required files:"
        for file in "${missing_files[@]}"; do
            log_error "  - $file"
        done
        exit 1
    fi
    
    log_info "All prerequisites validated"
}

# Setup keychain for signing
setup_keychain() {
    log_step "Setting up keychain"
    
    # Delete existing keychain if it exists
    if security list-keychains | grep -q "$KEYCHAIN_NAME"; then
        log_info "Removing existing keychain"
        security delete-keychain "$KEYCHAIN_NAME"
    fi
    
    # Create new keychain
    log_info "Creating new keychain: $KEYCHAIN_NAME"
    security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME"
    
    # Set keychain settings
    security set-keychain-settings -lut 21600 "$KEYCHAIN_NAME"
    security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME"
    
    # Add to keychain search list
    security list-keychains -d user -s "$KEYCHAIN_NAME" $(security list-keychains -d user | sed 's/"//g' | grep -v "$KEYCHAIN_NAME")
    security default-keychain -s "$KEYCHAIN_NAME"
    
    # Import WWDR certificate
    log_info "Importing WWDR certificate"
    security import "$WWDR_CERT_PATH" -k "$KEYCHAIN_NAME" -T /usr/bin/codesign
    
    # Import developer certificate
    log_info "Importing developer certificate"
    # Try direct P12 import first
    if ! security import "$P12_PATH" -k "$KEYCHAIN_NAME" -P "$P12_PASSWORD" -T /usr/bin/codesign -T /usr/bin/security -T /usr/bin/productbuild 2>/dev/null; then
        log_warn "Direct P12 import failed, trying OpenSSL extraction method"
        # Use openssl to extract certificate and key, then import separately
        openssl pkcs12 -in "$P12_PATH" -out temp_cert.pem -clcerts -nokeys -passin pass:"$P12_PASSWORD"
        openssl pkcs12 -in "$P12_PATH" -out temp_key.pem -nocerts -nodes -passin pass:"$P12_PASSWORD"
        
        # Import certificate
        security import temp_cert.pem -k "$KEYCHAIN_NAME" -T /usr/bin/codesign
        
        # Import private key
        security import temp_key.pem -k "$KEYCHAIN_NAME" -T /usr/bin/codesign -A
        
        # Clean up temporary files
        rm -f temp_cert.pem temp_key.pem
    else
        log_info "P12 imported successfully"
    fi
    
    # Set key partition list (prevents UI prompts)
    security set-key-partition-list -S apple-tool:,apple: -s -k "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME"
    
    log_info "Keychain setup complete"
}

# Prepare app for signing
prepare_app() {
    log_step "Preparing app for signing"
    
    # Remove old signature if exists
    if [[ -d "$APP_PATH/_CodeSignature" ]]; then
        log_info "Removing existing signature"
        rm -rf "$APP_PATH/_CodeSignature"
    fi
    
    # Copy provisioning profile
    log_info "Embedding provisioning profile"
    cp "$PROVISION_PATH" "$APP_PATH/embedded.mobileprovision"
    
    # Remove extended attributes
    log_info "Removing extended attributes"
    xattr -cr "$APP_PATH"
    
    log_info "App preparation complete"
}

# Sign the app
sign_app() {
    log_step "Signing app"
    
    local cert_hash="$CERTIFICATE_HASH"
    
    # Find the certificate hash dynamically if not provided
    if [[ -z "${cert_hash}" ]]; then
        log_info "Finding certificate hash dynamically"
        cert_hash=$(security find-identity -v -p codesigning "$KEYCHAIN_NAME" | grep -o -E '[0-9A-F]{40}' | head -1)
        if [[ -z "$cert_hash" ]]; then
            log_error "No valid signing certificate found in keychain"
            exit 1
        fi
    fi
    
    log_info "Using certificate: $cert_hash"
    log_info "Bundle path: $APP_PATH"
    
    # Perform signing
    codesign \
        --force \
        --sign "$cert_hash" \
        --entitlements "$ENTITLEMENTS_PATH" \
        --keychain "$KEYCHAIN_NAME" \
        --timestamp=none \
        --generate-entitlement-der \
        "$APP_PATH"
    
    log_info "App signed successfully"
}

# Verify signature
verify_signature() {
    log_step "Verifying signature"
    
    # Basic verification
    codesign --verify --verbose "$APP_PATH"
    
    # Detailed verification
    codesign -dvvv "$APP_PATH"
    
    log_info "Signature verification complete"
}

# Create IPA package
create_ipa() {
    log_step "Creating IPA package"
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    # Create Payload directory
    local temp_payload="$OUTPUT_DIR/Payload"
    rm -rf "$temp_payload"
    mkdir -p "$temp_payload"
    
    # Copy app to Payload
    cp -R "$APP_PATH" "$temp_payload/"
    
    # Create IPA
    local ipa_name="$(basename "$APP_PATH" .app).ipa"
    local ipa_path="$OUTPUT_DIR/$ipa_name"
    
    log_info "Creating IPA: $ipa_path"
    (cd "$OUTPUT_DIR" && zip -qr "$ipa_name" Payload)
    
    # Cleanup
    rm -rf "$temp_payload"
    
    log_info "IPA created successfully: $ipa_path"
    return 0
}

# Cleanup keychain
cleanup_keychain() {
    log_step "Cleaning up"
    
    if security list-keychains | grep -q "$KEYCHAIN_NAME"; then
        log_info "Removing build keychain"
        security delete-keychain "$KEYCHAIN_NAME"
    fi
    
    log_info "Cleanup complete"
}

# Main execution
main() {
    log_info "iOS App Signing Script v1.0.0"
    log_info "Project root: $PROJECT_ROOT"
    
    # Validate prerequisites
    validate_prerequisites
    
    # Setup keychain
    setup_keychain
    
    # Prepare app
    prepare_app
    
    # Sign app
    sign_app
    
    # Verify signature
    verify_signature
    
    # Create IPA
    create_ipa
    
    # Cleanup
    cleanup_keychain
    
    log_info "✅ Signing process completed successfully!"
}

# Run main function
main "$@"