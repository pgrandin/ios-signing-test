#!/bin/bash
set -e

# Qt6 App Testing Script
# Verifies the app is installed and provides manual testing instructions

DEVICE_ID="00008110-000E28D00A51801E"
BUNDLE_ID="org.kazer.ios-test"

echo "═══════════════════════════════════════"
echo "   Qt6 App Testing Verification"
echo "═══════════════════════════════════════"
echo

# Check device
echo "[1/3] Checking device connection..."
if idevice_id -n | grep -q "$DEVICE_ID"; then
    DEVICE_NAME=$(ideviceinfo -u "$DEVICE_ID" -k DeviceName 2>/dev/null || echo "iPhone")
    echo "✓ Device: $DEVICE_NAME (WiFi)"
else
    echo "⚠ Device not accessible via WiFi for logging"
fi
echo

# Verify installation
echo "[2/3] Verifying Qt6 app installation..."
if ios-deploy --id "$DEVICE_ID" --bundle_id "$BUNDLE_ID" --exists 2>&1 | grep -q "true"; then
    echo "✓ Qt6 app is installed"
else
    echo "❌ App not found"
    exit 1
fi
echo

# Check IPA contents
echo "[3/3] Verifying Qt6 app contents..."
if [ -f "signed-ios-app/HelloWorld.ipa" ]; then
    echo "IPA Details:"
    echo "  Size: $(ls -lh signed-ios-app/HelloWorld.ipa | awk '{print $5}')"

    # Check for Qt libraries
    QT_LIBS=$(unzip -l signed-ios-app/HelloWorld.ipa 2>/dev/null | grep -c "Qt" || echo "0")
    echo "  Qt References: $QT_LIBS"

    # Check executable
    if unzip -l signed-ios-app/HelloWorld.ipa 2>/dev/null | grep -q "HelloWorldQt6$"; then
        EXE_SIZE=$(unzip -l signed-ios-app/HelloWorld.ipa 2>/dev/null | grep "HelloWorldQt6$" | awk '{print $1}')
        echo "  Executable: HelloWorldQt6 ($(numfmt --to=iec-i --suffix=B $EXE_SIZE 2>/dev/null || echo $EXE_SIZE bytes))"
    fi
fi
echo

echo "═══════════════════════════════════════"
echo "✅ APP VERIFICATION COMPLETE"
echo "═══════════════════════════════════════"
echo
echo "📱 MANUAL TESTING REQUIRED:"
echo
echo "1. On your iPhone, find the 'Hello World' app"
echo
echo "2. Tap the icon to launch"
echo
echo "3. Verify you see:"
echo "   ✓ 'Hello World from Qt6!' (large text)"
echo "   ✓ 'Built with GitHub Actions + CMake' (subtitle)"
echo "   ✓ Clean QML-rendered interface"
echo
echo "4. If you see 'Untrusted Developer':"
echo "   • Settings → General → VPN & Device Management"
echo "   • Tap 'Pierre Grandin' → Trust"
echo "   • Return to Home and launch again"
echo
echo "5. Report results:"
echo "   ✓ App launches successfully"
echo "   ✓ UI displays correctly"
echo "   ✓ No crashes"
echo
echo "═══════════════════════════════════════"
echo
echo "Technical Details:"
echo "  Bundle ID: $BUNDLE_ID"
echo "  Framework: Qt 6.8.1 + QML"
echo "  Build: GitHub Actions (qt6-cmake-app branch)"
echo "  Deployment: WiFi/USB via ios-deploy"
echo
echo "Note: System logs require DeveloperDiskImage or USB connection"
echo "      Manual testing on device is the primary verification method"
echo
