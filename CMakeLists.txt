cmake_minimum_required(VERSION 3.16)

project(XingChenProj VERSION 0.1 LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2)

set_source_files_properties(qml/Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
)

qt_add_executable(XingChenProj
    WIN32
    main.cpp
)

qt_add_qml_module(XingChenProj
    URI XingChenProj
    VERSION 1.0
    RESOURCE_PREFIX /qt/qml
    SOURCES
        backend/backend.h
        backend/backend.cpp
        historymodel.h
        historymodel.cpp
        studentmodel.h
        studentmodel.cpp
    QML_FILES
        qml/Main.qml
        qml/Theme.qml
        qml/Outline.qml
        qml/Roster.qml
        qml/Detail.qml
    RESOURCES
        qml/qmldir
        RES/Lora-Regular.ttf
)

target_link_libraries(XingChenProj PRIVATE Qt6::Quick Qt6::QuickControls2)

set_target_properties(XingChenProj PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin"
)
