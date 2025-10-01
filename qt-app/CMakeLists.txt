cmake_minimum_required(VERSION 3.16)
project(HelloWorldQt6 VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# Find Qt6
find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Qml)

# Qt resource file
qt6_add_resources(QML_RESOURCES qml.qrc)

# Create executable
add_executable(HelloWorldQt6
    main.cpp
    ${QML_RESOURCES}
)

# Link Qt libraries
target_link_libraries(HelloWorldQt6 PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Qml
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
endif()
