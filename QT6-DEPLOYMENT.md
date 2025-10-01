# Qt6 + CMake iOS Deployment Guide

Complete automation pipeline for building and deploying Qt6 apps to iOS devices using GitHub Actions.

## ✅ What Was Built

### Qt6 QML Application
- **Framework**: Qt 6.8.1 with QML
- **Build System**: CMake
- **UI**: Native QML interface
- **Size**: 7.0 MB IPA
- **Display**: "Hello World from Qt6!" with subtitle

### Architecture
```
qt-app/
├── main.cpp          # Qt6 application entry point
├── main.qml          # QML UI definition
├── qml.qrc           # Qt resource file
├── CMakeLists.txt    # CMake build configuration
└── Info.plist        # iOS app metadata
```

## 🚀 Quick Start

### Automatic Deployment
```bash
./deploy-qt6-auto.sh
```

This script:
1. Downloads latest Qt6 build from GitHub Actions
2. Detects connected iOS device (WiFi or USB)
3. Deploys app to device
4. Verifies installation

### Manual Deployment
```bash
# Download latest build
gh run download $(gh run list --workflow=ios-build-sign.yml \
  --branch=qt6-cmake-app --status=success --limit 1 \
  --json databaseId --jq '.[0].databaseId') \
  --pattern signed-ios-app

# Deploy
ios-deploy --bundle signed-ios-app/HelloWorld.ipa
```

### Trigger New Build
```bash
gh workflow run ios-build-sign.yml --ref qt6-cmake-app

# Monitor progress
gh run watch
```

## 🔧 How It Works

### GitHub Actions Workflow

#### 1. Install Qt6 for iOS
```yaml
# Install aqtinstall (Qt installer)
pip3 install --break-system-packages aqtinstall

# Install Qt6 for macOS (host tools for cross-compilation)
aqt install-qt mac desktop 6.8.1 clang_64 --outputdir $GITHUB_WORKSPACE/Qt

# Install Qt6 for iOS (target platform)
aqt install-qt mac ios 6.8.1 --outputdir $GITHUB_WORKSPACE/Qt
```

**Why both?**
- macOS Qt6 provides host tools (moc, rcc, uic) needed for cross-compilation
- iOS Qt6 provides the target libraries and frameworks

#### 2. Build with CMake
```bash
cmake ../qt-app \
  -DCMAKE_PREFIX_PATH="$QT_PATH" \
  -DCMAKE_TOOLCHAIN_FILE="$QT_PATH/lib/cmake/Qt6/qt.toolchain.cmake" \
  -DCMAKE_BUILD_TYPE=Release \
  -DQT_HOST_PATH="$QT_HOST_PATH" \
  -G Xcode

xcodebuild \
  -project HelloWorldQt6.xcodeproj \
  -scheme HelloWorldQt6 \
  -configuration Release \
  -sdk iphoneos \
  -arch arm64
```

#### 3. Sign and Package
- Embeds provisioning profile
- Signs with development certificate
- Creates IPA with Payload structure
- Uploads as GitHub artifact

### Build Times
- **Qt6 Download**: ~2-3 minutes (macOS + iOS = ~1.5 GB)
- **CMake Configure**: ~20 seconds
- **Xcode Build**: ~30 seconds
- **Sign & Package**: ~10 seconds
- **Total**: ~4-5 minutes

## 📱 Testing on Device

### Initial Trust
When you first launch the app, you'll see "Untrusted Developer":

1. Go to **Settings**
2. **General** → **VPN & Device Management**
3. Tap **Pierre Grandin**
4. Tap **Trust**

### Verify App is Running
The Qt6 app displays:
- Large blue text: "Hello World from Qt6!"
- Subtitle: "Built with GitHub Actions + CMake"
- QML-rendered interface (native iOS look)

## 🛠️ Development Workflow

### Make Code Changes

1. **Edit QML UI** (`qt-app/main.qml`):
```qml
Text {
    text: "Your custom message!"
    font.pixelSize: 32
    color: "#007AFF"
}
```

2. **Edit C++ logic** (`qt-app/main.cpp`):
```cpp
// Add custom application logic
```

3. **Commit and push**:
```bash
git add qt-app/
git commit -m "Update Qt6 app"
git push
```

4. **Trigger build**:
```bash
gh workflow run ios-build-sign.yml --ref qt6-cmake-app
```

5. **Deploy when ready**:
```bash
./deploy-qt6-auto.sh
```

### Add Qt Modules

Edit `qt-app/CMakeLists.txt`:
```cmake
find_package(Qt6 REQUIRED COMPONENTS
    Core
    Gui
    Quick
    Qml
    Network  # Add new modules
    Svg
)

target_link_libraries(HelloWorldQt6 PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Qml
    Qt6::Network  # Link new modules
    Qt6::Svg
)
```

Then rebuild via GHA.

## 🔍 Technical Details

### CMake Configuration

**Key CMake settings for iOS**:
```cmake
-DCMAKE_PREFIX_PATH="$QT_PATH"                    # Where to find Qt6
-DCMAKE_TOOLCHAIN_FILE="qt.toolchain.cmake"      # Qt's iOS toolchain
-DQT_HOST_PATH="$QT_HOST_PATH"                   # Host tools location
-DCMAKE_BUILD_TYPE=Release                        # Release build
-G Xcode                                          # Use Xcode generator
```

### Why Xcode Generator?
- Qt6 for iOS requires Xcode project structure
- Handles framework embedding automatically
- Manages code signing attributes
- Creates proper app bundle structure

### Qt6 Resource System
The `qml.qrc` file embeds QML files into the binary:
```xml
<RCC>
    <qresource prefix="/">
        <file>main.qml</file>
    </qresource>
</RCC>
```

Accessed in code via `qrc:/main.qml`.

## 📊 App Comparison

| Feature | Native UIKit | Qt6 QML |
|---------|-------------|---------|
| Size | 20 KB | 7.0 MB |
| Framework | iOS UIKit | Qt 6.8.1 |
| Language | Objective-C | C++ + QML |
| UI Definition | Code | Declarative QML |
| Cross-platform | iOS only | iOS + Android + Desktop |
| Build Time | 30 sec | 5 min |

## 🐛 Troubleshooting

### Build Fails: Qt6CoreTools Not Found
**Cause**: Missing macOS host tools

**Fix**: Workflow installs both:
```bash
aqt install-qt mac desktop 6.8.1 clang_64  # Host tools
aqt install-qt mac ios 6.8.1                # Target
```

### Build Fails: Invalid artifact path
**Cause**: `find` returns paths like `./Release-iphoneos/App.app`

**Fix**: Strip `./` prefix with sed:
```bash
APP_PATH=$(find . -name "*.app" | sed 's|^./||')
```

### App Crashes on Launch
**Cause**: Bundle ID mismatch

**Fix**: Verify with:
```bash
plutil -p HelloWorldQt6.app/Info.plist | grep CFBundleIdentifier
# Should show: org.kazer.ios-test
```

### Qt6 Download Too Slow
**Workaround**: Use Qt online installer to pre-download, then cache in GHA:
```yaml
- uses: actions/cache@v3
  with:
    path: ${{ github.workspace }}/Qt
    key: qt-6.8.1-ios-macos
```

## 📁 Repository Structure

```
ios-signing-test/
├── qt-app/                        # Qt6 source code
│   ├── main.cpp
│   ├── main.qml
│   ├── qml.qrc
│   ├── CMakeLists.txt
│   └── Info.plist
├── .github/workflows/
│   └── ios-build-sign.yml         # Build pipeline
├── deploy-qt6-auto.sh             # Automated deployment
├── signed-ios-app/
│   └── HelloWorld.ipa             # Latest build (7.0 MB)
└── QT6-DEPLOYMENT.md              # This file
```

## 🎯 Success Criteria

- ✅ Qt6 6.8.1 installed for iOS cross-compilation
- ✅ CMake builds QML app with Xcode generator
- ✅ App signed with development certificate
- ✅ IPA created and uploaded to GitHub
- ✅ Automated deployment to device over WiFi
- ✅ App launches and displays QML interface

## 🔑 Requirements

- **Xcode**: Latest stable (on GHA runners)
- **Qt**: 6.8.1 (downloaded via aqtinstall)
- **CMake**: 3.16+ (included with macOS)
- **Certificate**: Valid until April 20, 2026
- **Provisioning Profile**: org.kazer.ios-test

## 📚 Resources

- [Qt for iOS](https://doc.qt.io/qt-6/ios.html)
- [CMake Qt6 Documentation](https://doc.qt.io/qt-6/cmake-get-started.html)
- [aqtinstall](https://github.com/miurahr/aqtinstall)
- [ios-deploy](https://github.com/ios-control/ios-deploy)

## 🎉 Next Steps

### Enhance the App
- Add interactive buttons and controls
- Implement navigation with Qt Quick Controls
- Add networking with QtNetwork
- Store data with Qt SQLite

### Optimize Build
- Cache Qt6 installation between runs
- Use ccache for faster C++ compilation
- Enable incremental builds

### Deploy to TestFlight
- Archive with proper provisioning
- Upload to App Store Connect
- Distribute to beta testers

---

**Branch**: `qt6-cmake-app`
**Build URL**: https://github.com/pgrandin/ios-signing-test/actions
**Last Updated**: 2025-10-01
