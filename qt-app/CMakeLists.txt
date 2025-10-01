cmake_minimum_required(VERSION 3.16)
project(HelloWorldQt6 VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

# Find Qt6 - Core, Gui, and QML components
find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)

# Create executable
qt_add_executable(HelloWorldQt6
    main.cpp
)

# Link Qt libraries
target_link_libraries(HelloWorldQt6 PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
)

# iOS specific settings
if(IOS)
    set_target_properties(HelloWorldQt6 PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Info.plist"
        XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "org.kazer.ios-test"
        XCODE_ATTRIBUTE_DEVELOPMENT_TEAM "4D6V9Q7PN2"
        XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "iPhone Developer"
        XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "13.0"
    )

    # Import iOS platform plugin statically
    qt_import_plugins(HelloWorldQt6
        INCLUDE Qt::QIOSIntegrationPlugin
    )

    # Finalize the app for iOS
    qt_finalize_target(HelloWorldQt6)
endif()
