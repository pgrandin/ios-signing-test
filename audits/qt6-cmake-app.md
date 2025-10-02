# Audit: qt6-cmake-app

## 1. Adopt Qt's standard CMake setup helper
- **Problem**: The project configures the executable manually and never calls `qt_standard_project_setup()`, so common Qt build
  defaults such as automatic MOC/RCC discovery, default warning levels, and standard release flags are skipped. 【F:qt6-cmake-app/CMakeLists.txt†L5-L22】
- **Fix**: Call `qt_standard_project_setup()` right after `find_package(Qt6 ...)` to opt into Qt's recommended compiler options and
  code-generation helpers for every target.

## 2. Prefer module-based QML loading from C++
- **Problem**: The engine loads `Main.qml` via a raw `qrc:` URL string, which can drift from the module name defined in CMake and
  bypasses compile-time validation that the QML file exists. 【F:qt6-cmake-app/CMakeLists.txt†L12-L18】【F:qt6-cmake-app/src/main.cpp†L9-L18】
- **Fix**: Replace the manual `engine.load(url)` call with `engine.loadFromModule("Qt6CmakeApp", "Main")`, so the C++ bootstrapping
  code uses the same module ID managed by `qt_add_qml_module`.
