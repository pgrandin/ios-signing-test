#!/bin/bash
set -euo pipefail

# Create IPA from signed app bundle

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <app-path>"
    echo "Example: $0 app/SampleApp.app"
    exit 1
fi

APP_PATH="$1"
APP_NAME="$(basename "$APP_PATH" .app)"
OUTPUT_DIR="${OUTPUT_DIR:-output}"

# Verify app exists
if [[ ! -d "$APP_PATH" ]]; then
    echo "Error: App not found at $APP_PATH"
    exit 1
fi

# Verify app is signed
if ! codesign --verify "$APP_PATH" 2>/dev/null; then
    echo "Error: App is not properly signed"
    exit 1
fi

echo "Creating IPA for $APP_NAME..."

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Create Payload directory
TEMP_DIR="$OUTPUT_DIR/temp_$$"
mkdir -p "$TEMP_DIR/Payload"

# Copy app to Payload
cp -R "$APP_PATH" "$TEMP_DIR/Payload/"

# Create IPA
IPA_PATH="$OUTPUT_DIR/${APP_NAME}.ipa"
(cd "$TEMP_DIR" && zip -qr "../${APP_NAME}.ipa" Payload)

# Cleanup
rm -rf "$TEMP_DIR"

echo "✅ IPA created: $IPA_PATH"