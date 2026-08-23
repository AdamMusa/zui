cmake_minimum_required(VERSION 3.21)
project(zui-host VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.8 REQUIRED COMPONENTS
  Core
  Gui
  Multimedia
  Qml
  Quick
  QuickControls2
  QuickVectorImage
)
find_package(Qt6 6.8 QUIET COMPONENTS WebEngineQuick)

qt_add_executable(zui-host
  main.cpp
  ZuiClipboard.cpp
  ZuiClipboard.h
  ZuiProcess.cpp
  ZuiProcess.h
)

target_link_libraries(zui-host PRIVATE
  Qt6::Core
  Qt6::Gui
  Qt6::Multimedia
  Qt6::Qml
  Qt6::Quick
  Qt6::QuickControls2
  Qt6::QuickVectorImage
)

if(TARGET Qt6::WebEngineQuick)
  target_link_libraries(zui-host PRIVATE Qt6::WebEngineQuick)
  target_compile_definitions(zui-host PRIVATE ZUI_HAS_WEBENGINE=1)
endif()

install(TARGETS zui-host
  BUNDLE DESTINATION .
  RUNTIME DESTINATION bin
)
