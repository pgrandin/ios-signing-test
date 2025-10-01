# Qt6 App Launch Instructions

## Current Status

✅ **Qt6 app successfully built and deployed to your device**

- **App Name**: Hello World
- **Bundle ID**: org.kazer.ios-test
- **Framework**: Qt 6.8.1 + QML
- **Size**: 7.0 MB
- **Device**: iPhone 13 Pro
- **Build**: GitHub Actions (qt6-cmake-app branch)

## Launch the App

### Method 1: Manual Launch (Recommended)

**On your iPhone:**

1. **Find the app icon**
   - Look for "Hello World" on your Home Screen
   - It should have a generic app icon (white with grid)

2. **First launch - Trust the developer**
   - Tap the "Hello World" icon
   - You'll see: **"Untrusted Enterprise Developer"**
   - Tap "Cancel"

3. **Trust the certificate**
   - Go to **Settings**
   - Scroll down to **General**
   - Tap **VPN & Device Management** (or **Device Management**)
   - Under "Developer App", tap **Pierre Grandin**
   - Tap **Trust "Pierre Grandin"**
   - Tap **Trust** in the confirmation dialog

4. **Launch again**
   - Return to Home Screen
   - Tap "Hello World" icon
   - App should launch!

### Method 2: Via ios-deploy (Limited)

```bash
# This requires USB connection and DeveloperDiskImage support
# Not reliable over WiFi
ios-deploy --id 00008110-000E28D00A51801E --bundle signed-ios-app/HelloWorld.ipa --debug --noninteractive
```

## What You Should See

When the Qt6 app launches successfully, you should see:

```
╔══════════════════════════════════╗
║                                  ║
║   Hello World from Qt6!          ║
║                                  ║
║   Built with GitHub Actions      ║
║   + CMake                        ║
║                                  ║
╚══════════════════════════════════╝
```

### Expected Behavior:
- **Large blue text**: "Hello World from Qt6!"
- **Gray subtitle**: "Built with GitHub Actions + CMake"
- **Clean interface**: QML-rendered UI with proper iOS styling
- **No crashes**: App stays open and responsive

## Verification Checklist

After launching, verify:

- [ ] App icon appears on device
- [ ] Tapping icon launches the app (after trusting developer)
- [ ] Main text displays correctly
- [ ] Subtitle displays correctly
- [ ] UI renders properly (no blank screen)
- [ ] App doesn't crash immediately
- [ ] Can navigate away and return to app

## Troubleshooting

### Issue: "Untrusted Enterprise Developer"
**Solution**: Follow step 3 above to trust the certificate

### Issue: App crashes on launch
**Possible causes**:
- Bundle ID mismatch with provisioning profile
- Missing Qt libraries (shouldn't happen - they're bundled)
- Code signing issue

**Debug**:
```bash
# Check signature
codesign -vvv signed-ios-app/HelloWorld.app 2>&1

# Verify bundle ID
plutil -p signed-ios-app/HelloWorld.app/Info.plist | grep CFBundleIdentifier
```

### Issue: Blank/white screen
**Possible causes**:
- QML file not loading from resources
- Qt Quick module issue

**Check**:
```bash
# Verify QML is in IPA
unzip -l signed-ios-app/HelloWorld.ipa | grep qml
```

### Issue: App not appearing on device
**Solution**:
```bash
# Verify installation
ios-deploy --id 00008110-000E28D00A51801E --bundle_id org.kazer.ios-test --exists

# Should return: true
```

## Technical Details

### App Architecture
```
HelloWorldQt6.app/
├── HelloWorldQt6          # Executable (20.5 MB)
├── Info.plist             # App metadata
├── embedded.mobileprovision
├── _CodeSignature/
│   └── CodeResources
└── [Qt6 frameworks bundled in executable]
```

### Qt6 Components Used
- **Qt6::Core** - Core functionality
- **Qt6::Gui** - GUI support
- **Qt6::Quick** - QML engine
- **Qt6::Qml** - QML runtime

### Build Configuration
- **Qt Version**: 6.8.1
- **Target**: iOS 13.0+
- **Architecture**: arm64
- **Build Type**: Release
- **Compiler**: Apple Clang 17.0
- **Generator**: Xcode

## Logs (If Accessible)

For USB-connected devices with Xcode paired:

```bash
# Real-time logs
idevicesyslog -u 00008110-000E28D00A51801E | grep -i "hello\|qt\|org.kazer"

# Or use Console.app on Mac
# Filter by process: HelloWorldQt6
```

## Success Criteria

**✅ The Qt6 app is working if:**
1. App launches without crashing
2. UI displays the expected text
3. QML interface renders correctly
4. App remains stable (doesn't crash after a few seconds)

**📊 Performance expectations:**
- Launch time: < 3 seconds
- Memory usage: ~30-50 MB
- Smooth UI rendering

## Next Steps After Verification

Once you confirm the app works:

1. **Make changes** to `qt-app/main.qml`
2. **Commit and push** to `qt6-cmake-app` branch
3. **Trigger build**: `gh workflow run ios-build-sign.yml --ref qt6-cmake-app`
4. **Wait for build** (~5 minutes)
5. **Deploy update**: `./deploy-qt6-auto.sh`

## Report Results

Please report:
- ✅ App launches successfully: [YES/NO]
- ✅ UI displays correctly: [YES/NO]
- ✅ No crashes: [YES/NO]
- 📸 Screenshot of running app: [Optional]

---

**Built**: 2025-10-01 via GitHub Actions
**Branch**: qt6-cmake-app
**Commit**: c69b053
