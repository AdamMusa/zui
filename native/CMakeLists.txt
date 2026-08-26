cmake_minimum_required(VERSION 3.21)
project(zui-host LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.8 REQUIRED COMPONENTS
  Core
  Gui
  Qml
  Quick
  QuickControls2
)

option(ZUI_EMBEDDED_RUNTIME "Embed mruby for mobile application targets" OFF)
set(ZUI_MRUBY_ROOT "" CACHE PATH "mruby source/build root for an embedded target")
set(ZUI_MRUBY_BUILD "zui-ios-simulator" CACHE STRING "mruby build name")
set(ZUI_MOBILE_APP_DIR "" CACHE PATH "Generated mobile application resource directory")
set(ZUI_MOBILE_APP_NAME "Zui Mobile" CACHE STRING "Mobile application display name")
set(ZUI_MOBILE_BUNDLE_ID "dev.zui.mobile" CACHE STRING "Mobile application bundle identifier")
set(ZUI_MOBILE_APP_VERSION "0.1.0" CACHE STRING "Mobile application release version")
set(ZUI_MOBILE_BUILD_VERSION "1" CACHE STRING "Mobile application build version")
set(ZUI_IOS_LAUNCH_SCREEN "${CMAKE_CURRENT_SOURCE_DIR}/LaunchScreen.storyboard" CACHE FILEPATH "iOS launch storyboard")
set(ZUI_ANDROID_PACKAGE_SOURCE_DIR "" CACHE PATH "Android package template overlay")
set(ZUI_ANDROID_MIN_SDK "23" CACHE STRING "Android minimum SDK version")
set(ZUI_ANDROID_TARGET_SDK "35" CACHE STRING "Android target SDK version")

set(zui_host_sources
  main.cpp
  ZuiClipboard.cpp
  ZuiClipboard.h
  ZuiSafeArea.h
)

if(IOS)
  enable_language(OBJCXX)
  list(APPEND zui_host_sources ZuiSafeArea.mm)
else()
  list(APPEND zui_host_sources ZuiSafeArea.cpp)
endif()

if(ZUI_EMBEDDED_RUNTIME)
  if(NOT IS_DIRECTORY "${ZUI_MRUBY_ROOT}/include")
    message(FATAL_ERROR "ZUI_MRUBY_ROOT must point to a built mruby source tree")
  endif()
  if(NOT IS_DIRECTORY "${ZUI_MOBILE_APP_DIR}" OR NOT EXISTS "${ZUI_MOBILE_APP_DIR}/app.mrb")
    message(FATAL_ERROR "ZUI_MOBILE_APP_DIR must contain precompiled app.mrb")
  endif()
  set(zui_mruby_library "${ZUI_MRUBY_ROOT}/build/${ZUI_MRUBY_BUILD}/lib/libmruby.a")
  if(NOT EXISTS "${zui_mruby_library}")
    message(FATAL_ERROR "Embedded mruby library not found: ${zui_mruby_library}")
  endif()
  list(APPEND zui_host_sources ZuiEmbeddedRuntime.cpp ZuiEmbeddedRuntime.h)
else()
  list(APPEND zui_host_sources ZuiProcess.cpp ZuiProcess.h)
endif()

qt_add_executable(zui-host ${zui_host_sources})

set_target_properties(zui-host PROPERTIES
  MACOSX_BUNDLE TRUE
  WIN32_EXECUTABLE TRUE
)

target_link_libraries(zui-host PRIVATE
  Qt6::Core
  Qt6::Gui
  Qt6::Qml
  Qt6::Quick
  Qt6::QuickControls2
)

if(ZUI_EMBEDDED_RUNTIME)
  string(REPLACE "\\" "\\\\" zui_mobile_app_name_definition "${ZUI_MOBILE_APP_NAME}")
  string(REPLACE "\"" "\\\"" zui_mobile_app_name_definition "${zui_mobile_app_name_definition}")
  target_include_directories(zui-host PRIVATE
    "${ZUI_MRUBY_ROOT}/include"
    "${ZUI_MRUBY_ROOT}/build/${ZUI_MRUBY_BUILD}/include"
  )
  target_link_libraries(zui-host PRIVATE "${zui_mruby_library}")
  target_compile_definitions(zui-host PRIVATE
    ZUI_EMBEDDED_RUNTIME=1
    ZUI_MOBILE_APP_NAME="${zui_mobile_app_name_definition}"
  )
  if(ANDROID)
    set_target_properties(zui-host PROPERTIES
      OUTPUT_NAME "zui_host"
      QT_ANDROID_PACKAGE_NAME "${ZUI_MOBILE_BUNDLE_ID}"
      QT_ANDROID_VERSION_NAME "${ZUI_MOBILE_APP_VERSION}"
      QT_ANDROID_VERSION_CODE "${ZUI_MOBILE_BUILD_VERSION}"
      QT_ANDROID_MIN_SDK_VERSION "${ZUI_ANDROID_MIN_SDK}"
      QT_ANDROID_TARGET_SDK_VERSION "${ZUI_ANDROID_TARGET_SDK}"
      QT_ANDROID_PACKAGE_SOURCE_DIR "${ZUI_ANDROID_PACKAGE_SOURCE_DIR}"
    )
    target_link_libraries(zui-host PRIVATE m)
  else()
    set_target_properties(zui-host PROPERTIES
      OUTPUT_NAME "${ZUI_MOBILE_APP_NAME}"
      MACOSX_BUNDLE_GUI_IDENTIFIER "${ZUI_MOBILE_BUNDLE_ID}"
      MACOSX_BUNDLE_BUNDLE_NAME "${ZUI_MOBILE_APP_NAME}"
      MACOSX_BUNDLE_SHORT_VERSION_STRING "${ZUI_MOBILE_APP_VERSION}"
      MACOSX_BUNDLE_BUNDLE_VERSION "${ZUI_MOBILE_BUILD_VERSION}"
      XCODE_ATTRIBUTE_PRODUCT_NAME "${ZUI_MOBILE_APP_NAME}"
    )
  endif()
  if(IOS)
    set_target_properties(zui-host PROPERTIES
      QT_IOS_LAUNCH_SCREEN "${ZUI_IOS_LAUNCH_SCREEN}"
    )
  endif()

  get_filename_component(ZUI_FRAMEWORK_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/.." ABSOLUTE)
  file(GLOB zui_qml_entrypoints CONFIGURE_DEPENDS "${ZUI_FRAMEWORK_ROOT}/*.qml")
  file(GLOB_RECURSE zui_qml_resources CONFIGURE_DEPENDS
    "${ZUI_FRAMEWORK_ROOT}/Components/*.qml"
    "${ZUI_FRAMEWORK_ROOT}/Controls/*.qml"
    "${ZUI_FRAMEWORK_ROOT}/Controls/qmldir"
    "${ZUI_FRAMEWORK_ROOT}/Theme/*.qml"
    "${ZUI_FRAMEWORK_ROOT}/Theme/qmldir"
    "${ZUI_FRAMEWORK_ROOT}/Fonts/*.otf"
  )
  list(APPEND zui_qml_resources ${zui_qml_entrypoints})
  qt_add_resources(zui-host zui_mobile_runtime
    PREFIX "/zui"
    BASE "${ZUI_FRAMEWORK_ROOT}"
    FILES ${zui_qml_resources}
  )

  file(GLOB_RECURSE zui_mobile_app_resources CONFIGURE_DEPENDS
    "${ZUI_MOBILE_APP_DIR}/*"
  )
  qt_add_resources(zui-host zui_mobile_application
    PREFIX "/app"
    BASE "${ZUI_MOBILE_APP_DIR}"
    FILES ${zui_mobile_app_resources}
  )

  if(IOS AND IS_DIRECTORY "${ZUI_MOBILE_APP_DIR}/Assets.xcassets")
    set_source_files_properties("${ZUI_MOBILE_APP_DIR}/Assets.xcassets" PROPERTIES
      MACOSX_PACKAGE_LOCATION "Resources"
    )
    target_sources(zui-host PRIVATE "${ZUI_MOBILE_APP_DIR}/Assets.xcassets")
    set_target_properties(zui-host PROPERTIES
      XCODE_ATTRIBUTE_ASSETCATALOG_COMPILER_APPICON_NAME "AppIcon"
    )
  endif()
endif()

if(ANDROID)
  install(TARGETS zui-host LIBRARY DESTINATION lib)
else()
  install(TARGETS zui-host
    BUNDLE DESTINATION .
    RUNTIME DESTINATION bin
  )
endif()

if((APPLE OR WIN32) AND NOT IOS)
  set(ZUI_QML_SCAN_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/.." CACHE PATH "QML tree scanned for deployment")
  set(zui_deploy_tool_options "")
  if(APPLE)
    list(APPEND zui_deploy_tool_options "-qmldir=${ZUI_QML_SCAN_ROOT}")
  else()
    list(APPEND zui_deploy_tool_options "--qmldir" "${ZUI_QML_SCAN_ROOT}")
  endif()

  qt_generate_deploy_app_script(
    TARGET zui-host
    OUTPUT_SCRIPT zui_deploy_script
    NO_TRANSLATIONS
    DEPLOY_TOOL_OPTIONS ${zui_deploy_tool_options}
  )
  install(SCRIPT ${zui_deploy_script})
endif()

if(IOS OR ANDROID)
  qt_import_qml_plugins(zui-host)
endif()
