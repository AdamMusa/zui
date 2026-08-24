cmake_minimum_required(VERSION 3.21)
project(zui-host LANGUAGES CXX)

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

set_target_properties(zui-host PROPERTIES
  MACOSX_BUNDLE TRUE
  WIN32_EXECUTABLE TRUE
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

if(APPLE OR WIN32)
  set(zui_deploy_tool_options "")
  if(APPLE)
    list(APPEND zui_deploy_tool_options "-qmldir=${CMAKE_CURRENT_SOURCE_DIR}/..")
  else()
    list(APPEND zui_deploy_tool_options "--qmldir" "${CMAKE_CURRENT_SOURCE_DIR}/..")
  endif()

  qt_generate_deploy_app_script(
    TARGET zui-host
    OUTPUT_SCRIPT zui_deploy_script
    NO_TRANSLATIONS
    DEPLOY_TOOL_OPTIONS ${zui_deploy_tool_options}
  )
  install(SCRIPT ${zui_deploy_script})
endif()
