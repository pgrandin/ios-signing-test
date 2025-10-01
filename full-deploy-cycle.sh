#!/bin/bash
set -euo pipefail

# Complete Deployment Cycle: Build → Download → Deploy → Launch → Monitor

BRANCH="${1:-qt6-hello-world}"
BUNDLE_ID="org.kazer.ios-test"

echo "=== Complete iOS Deployment Cycle ==="
echo "Branch: $BRANCH"
echo

# Step 1: Trigger build
echo "[1/6] Triggering GitHub Actions build..."
gh workflow run ios-build-sign.yml --ref "$BRANCH"
sleep 5

# Get the run ID
RUN_ID=$(gh run list --workflow=ios-build-sign.yml --branch="$BRANCH" --limit 1 --json databaseId --jq '.[0].databaseId')
echo "    Run ID: $RUN_ID"
echo "    URL: https://github.com/pgrandin/ios-signing-test/actions/runs/$RUN_ID"
echo

# Step 2: Monitor build
echo "[2/6] Monitoring build..."
while true; do
    STATUS=$(gh run view $RUN_ID --json status,conclusion --jq '{status: .status, conclusion: .conclusion}')
    CURRENT_STATUS=$(echo "$STATUS" | jq -r '.status')
    CONCLUSION=$(echo "$STATUS" | jq -r '.conclusion')

    printf "\r    Status: %-20s" "$CURRENT_STATUS"

    if [ "$CURRENT_STATUS" = "completed" ]; then
        echo
        if [ "$CONCLUSION" != "success" ]; then
            echo "    ❌ Build failed: $CONCLUSION"
            exit 1
        fi
        echo "    ✓ Build succeeded"
        break
    fi

    sleep 10
done
echo

# Step 3: Download artifacts
echo "[3/6] Downloading build artifacts..."
rm -rf signed-ios-app build-artifacts
gh run download "$RUN_ID" -R pgrandin/ios-signing-test --pattern signed-ios-app
IPA_PATH=$(find signed-ios-app -name "*.ipa" | head -1)
echo "    ✓ Downloaded: $IPA_PATH"
echo

# Step 4: Wait for device
echo "[4/6] Waiting for iOS device..."
while true; do
    if ios-deploy --detect --timeout 2 2>&1 | grep -q "Using"; then
        DEVICE_INFO=$(ios-deploy --detect --timeout 2 2>&1 | grep "Using" | head -1)
        echo "    ✓ $DEVICE_INFO"
        break
    fi
    printf "\r    Waiting for device connection..."
    sleep 2
done
echo

# Step 5: Deploy
echo "[5/6] Deploying to device..."
ios-deploy --bundle "$IPA_PATH" --no-wifi 2>&1 | \
    grep -E "\[.*%\].*Install" | tail -1
echo "    ✓ App installed"
echo

# Step 6: Verify installation
echo "[6/6] Verifying installation..."
if ios-deploy --bundle_id "$BUNDLE_ID" --exists --no-wifi 2>&1 | grep -q "true"; then
    echo "    ✓ App verified on device"
else
    echo "    ⚠ Could not verify app"
fi
echo

echo "════════════════════════════════════"
echo "✅ DEPLOYMENT COMPLETE"
echo "════════════════════════════════════"
echo
echo "App: Hello World"
echo "Bundle ID: $BUNDLE_ID"
echo "Size: $(ls -lh "$IPA_PATH" | awk '{print $5}')"
echo
echo "👉 Launch the app on your device to test!"
echo
