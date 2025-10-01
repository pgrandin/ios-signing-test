cmake_minimum_required(VERSION 3.21)
project(HelloWorldQt6 VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find Qt6 packages
find_package(Qt6 REQUIRED COMPONENTS Core Widgets)

# Enable automatic handling of Qt's MOC, UIC, and RCC
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# iOS specific settings
if(IOS)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "13.0" CACHE STRING "Minimum iOS version")
    set(CMAKE_OSX_ARCHITECTURES "arm64" CACHE STRING "Build architectures for iOS")
    set(CMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH NO)
    set(CMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE NO)
endif()

# Create the executable
add_executable(HelloWorldQt6
    main.cpp
)

# Link Qt6 libraries
target_link_libraries(HelloWorldQt6 PRIVATE
    Qt6::Core
    Qt6::Widgets
)

# iOS specific bundle settings
if(IOS)
    set_target_properties(HelloWorldQt6 PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_GUI_IDENTIFIER "org.kazer.ios-test"
        MACOSX_BUNDLE_BUNDLE_NAME "HelloWorldQt6"
        MACOSX_BUNDLE_BUNDLE_VERSION "1.0"
        MACOSX_BUNDLE_SHORT_VERSION_STRING "1.0"
        XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "org.kazer.ios-test"
        XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2"
        XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "13.0"
    )
endif()
