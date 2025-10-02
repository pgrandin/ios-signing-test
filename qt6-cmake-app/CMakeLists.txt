cmake_minimum_required(VERSION 3.21)
project(qt6_cmake_app LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick QuickControls2)

qt_add_executable(qt6_cmake_app
    src/main.cpp
)

qt_add_qml_module(qt6_cmake_app
    URI Qt6CmakeApp
    VERSION 1.0
    QML_FILES
        qml/Main.qml
)

target_link_libraries(qt6_cmake_app
    PRIVATE
        Qt6::Quick
        Qt6::QuickControls2
)
