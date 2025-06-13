#!/bin/bash
set -euo pipefail

# P12 Format Fixer for macOS Security Command
# Converts P12 files to legacy format for compatibility

if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <input.p12> <password>"
    echo "This script converts P12 files to a format compatible with macOS security command"
    exit 1
fi

INPUT_P12="$1"
PASSWORD="$2"
OUTPUT_P12="${INPUT_P12%.p12}_fixed.p12"

echo "Converting P12 to macOS-compatible format..."

# Extract all contents
openssl pkcs12 -in "$INPUT_P12" -passin "pass:$PASSWORD" -out temp_all.pem -nodes

# Re-export with legacy mode
openssl pkcs12 -export -legacy -in temp_all.pem -out "$OUTPUT_P12" -passout "pass:$PASSWORD"

# Clean up
rm -f temp_all.pem

echo "✅ Converted P12 saved as: $OUTPUT_P12"
echo "This file should now work with the macOS security command."