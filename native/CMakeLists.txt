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
option(ZUI_EMBEDDED_CRUBY "Embed CRuby for mobile application targets" OFF)
set(ZUI_MRUBY_ROOT "" CACHE PATH "mruby source/build root for an embedded target")
set(ZUI_MRUBY_BUILD "zui-ios-simulator" CACHE STRING "mruby build name")
set(ZUI_CRUBY_SOURCE_ROOT "" CACHE PATH "CRuby source root for an embedded target")
set(ZUI_CRUBY_BUILD_ROOT "" CACHE PATH "CRuby build root for an embedded target")
set(ZUI_CRUBY_LIBRARY "" CACHE FILEPATH "CRuby static library for an embedded target")
set(ZUI_MOBILE_APP_DIR "" CACHE PATH "Generated mobile application resource directory")
set(ZUI_MOBILE_APP_NAME "Zui Mobile" CACHE STRING "Mobile application display name")
set(ZUI_MOBILE_BUNDLE_ID "dev.zui.mobile" CACHE STRING "Mobile application bundle identifier")
set(ZUI_MOBILE_APP_VERSION "0.1.0" CACHE STRING "Mobile application release version")
set(ZUI_MOBILE_BUILD_VERSION "1" CACHE STRING "Mobile application build version")
set(ZUI_IOS_LAUNCH_SCREEN "${CMAKE_CURRENT_SOURCE_DIR}/LaunchScreen.storyboard" CACHE FILEPATH "iOS launch storyboard")
set(ZUI_IOS_INFO_PLIST "" CACHE FILEPATH "Custom iOS Info.plist template")
set(ZUI_IOS_ENTITLEMENTS "" CACHE FILEPATH "Custom iOS code-signing entitlements")
set(ZUI_IOS_PROJECT_DIR "" CACHE PATH "Project-owned iOS resources and native integration")
set(ZUI_ANDROID_PACKAGE_SOURCE_DIR "" CACHE PATH "Android package template overlay")
set(ZUI_ANDROID_PROJECT_DIR "" CACHE PATH "Project-owned Android native integration")
set(ZUI_ANDROID_MIN_SDK "23" CACHE STRING "Android minimum SDK version")
set(ZUI_ANDROID_TARGET_SDK "35" CACHE STRING "Android target SDK version")

set(zui_host_sources
  main.cpp
  ZuiClipboard.cpp
  ZuiClipboard.h
  ZuiSafeArea.h
)

if(IOS)
  enable_language(OBJC OBJCXX)
  list(APPEND zui_host_sources ZuiSafeArea.mm)
else()
  list(APPEND zui_host_sources ZuiSafeArea.cpp)
endif()

if(ZUI_EMBEDDED_CRUBY)
  set(ZUI_EMBEDDED_RUNTIME ON)
endif()

if(ZUI_EMBEDDED_RUNTIME AND ZUI_EMBEDDED_CRUBY)
  if(NOT IS_DIRECTORY "${ZUI_CRUBY_SOURCE_ROOT}/include")
    message(FATAL_ERROR "ZUI_CRUBY_SOURCE_ROOT must point to a CRuby source tree")
  endif()
  if(NOT IS_DIRECTORY "${ZUI_CRUBY_BUILD_ROOT}/.ext/include")
    message(FATAL_ERROR "ZUI_CRUBY_BUILD_ROOT must point to a configured CRuby build tree")
  endif()
  if(NOT EXISTS "${ZUI_CRUBY_LIBRARY}")
    message(FATAL_ERROR "Embedded CRuby library not found: ${ZUI_CRUBY_LIBRARY}")
  endif()
  set(zui_cruby_json_generator "${ZUI_CRUBY_BUILD_ROOT}/ext/json/generator/generator.a")
  set(zui_cruby_json_parser "${ZUI_CRUBY_BUILD_ROOT}/ext/json/parser/parser.a")
  set(zui_cruby_encodings "${ZUI_CRUBY_BUILD_ROOT}/enc/libenc.a")
  set(zui_cruby_standard_extensions
    "${ZUI_CRUBY_BUILD_ROOT}/ext/continuation/continuation.a"
    "${ZUI_CRUBY_BUILD_ROOT}/ext/coverage/coverage.a"
    "${ZUI_CRUBY_BUILD_ROOT}/ext/date/date_core.a"
    "${ZUI_CRUBY_BUILD_ROOT}/ext/digest/digest.a"
    "${ZUI_CRUBY_BUILD_ROOT}/ext/etc/etc.a"
    "${ZUI_CRUBY_BUILD_ROOT}/ext/fcntl/fcntl.a"
    "${ZUI_CRUBY_BUILD_ROOT}/ext/io/nonblock/nonblock.a"
    "${ZUI_CRUBY_BUILD_ROOT}/ext/io/wait/wait.a"
    "${ZUI_CRUBY_BUILD_ROOT}/ext/monitor/monitor.a"
    "${ZUI_CRUBY_BUILD_ROOT}/ext/objspace/objspace.a"
    "${ZUI_CRUBY_BUILD_ROOT}/ext/rbconfig/sizeof/sizeof.a"
    "${ZUI_CRUBY_BUILD_ROOT}/ext/stringio/stringio.a"
    "${ZUI_CRUBY_BUILD_ROOT}/ext/strscan/strscan.a"
  )
  if(NOT EXISTS "${zui_cruby_json_generator}" OR NOT EXISTS "${zui_cruby_json_parser}")
    message(FATAL_ERROR "ZUI_CRUBY_BUILD_ROOT must contain statically built JSON extensions")
  endif()
  if(NOT EXISTS "${zui_cruby_encodings}")
    message(FATAL_ERROR "ZUI_CRUBY_BUILD_ROOT must contain statically built encodings")
  endif()
  foreach(extension_library IN LISTS zui_cruby_standard_extensions)
    if(NOT EXISTS "${extension_library}")
      message(FATAL_ERROR "Embedded CRuby standard extension not found: ${extension_library}")
    endif()
  endforeach()
  if(NOT IS_DIRECTORY "${ZUI_MOBILE_APP_DIR}" OR NOT EXISTS "${ZUI_MOBILE_APP_DIR}/app.rb")
    message(FATAL_ERROR "ZUI_MOBILE_APP_DIR must contain app.rb")
  endif()
  foreach(json_source version common ext)
    if(NOT EXISTS "${ZUI_MOBILE_APP_DIR}/cruby/json/${json_source}.rb")
      message(FATAL_ERROR "ZUI_MOBILE_APP_DIR must contain cruby/json/${json_source}.rb")
    endif()
  endforeach()
  if(NOT EXISTS "${ZUI_MOBILE_APP_DIR}/cruby/json/ext/generator/state.rb")
    message(FATAL_ERROR "ZUI_MOBILE_APP_DIR must contain cruby/json/ext/generator/state.rb")
  endif()
  if(NOT EXISTS "${ZUI_MOBILE_APP_DIR}/cruby/gems.json")
    message(FATAL_ERROR "ZUI_MOBILE_APP_DIR must contain the locked CRuby gem manifest")
  endif()
  file(GLOB zui_cruby_arch_include "${ZUI_CRUBY_BUILD_ROOT}/.ext/include/*")
  list(APPEND zui_host_sources ZuiCRubyRuntime.cpp ZuiCRubyRuntime.h)
elseif(ZUI_EMBEDDED_RUNTIME)
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
  if(ZUI_EMBEDDED_CRUBY)
    target_include_directories(zui-host PRIVATE
      "${ZUI_CRUBY_SOURCE_ROOT}/include"
      ${zui_cruby_arch_include}
    )
    target_link_libraries(zui-host PRIVATE
      "${ZUI_CRUBY_LIBRARY}"
      "${zui_cruby_json_generator}"
      "${zui_cruby_json_parser}"
      "${zui_cruby_encodings}"
      ${zui_cruby_standard_extensions}
    )
    target_compile_definitions(zui-host PRIVATE ZUI_EMBEDDED_CRUBY=1)
    if(APPLE)
      find_library(ZUI_CORE_FOUNDATION CoreFoundation REQUIRED)
      target_link_libraries(zui-host PRIVATE "${ZUI_CORE_FOUNDATION}")
    endif()
  else()
    target_include_directories(zui-host PRIVATE
      "${ZUI_MRUBY_ROOT}/include"
      "${ZUI_MRUBY_ROOT}/build/${ZUI_MRUBY_BUILD}/include"
    )
    target_link_libraries(zui-host PRIVATE "${zui_mruby_library}")
  endif()
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
    if(EXISTS "${ZUI_IOS_INFO_PLIST}")
      set_target_properties(zui-host PROPERTIES
        MACOSX_BUNDLE_INFO_PLIST "${ZUI_IOS_INFO_PLIST}"
      )
    endif()
    if(EXISTS "${ZUI_IOS_ENTITLEMENTS}")
      set_target_properties(zui-host PROPERTIES
        XCODE_ATTRIBUTE_CODE_SIGN_ENTITLEMENTS "${ZUI_IOS_ENTITLEMENTS}"
      )
    endif()
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

  if(IOS AND IS_DIRECTORY "${ZUI_IOS_PROJECT_DIR}")
    set(zui_ios_control_file_pattern
      "/(Info\\.plist\\.in|Zui\\.entitlements|LaunchScreen\\.storyboard|Zui\\.cmake|Zui\\.xcconfig|README\\.md|\\.DS_Store)$"
    )
    file(GLOB zui_ios_root_resources CONFIGURE_DEPENDS LIST_DIRECTORIES false
      "${ZUI_IOS_PROJECT_DIR}/*"
    )
    list(FILTER zui_ios_root_resources EXCLUDE REGEX "${zui_ios_control_file_pattern}")
    foreach(resource IN LISTS zui_ios_root_resources)
      set_source_files_properties("${resource}" PROPERTIES MACOSX_PACKAGE_LOCATION "Resources")
    endforeach()

    file(GLOB_RECURSE zui_ios_nested_resources CONFIGURE_DEPENDS LIST_DIRECTORIES false
      "${ZUI_IOS_PROJECT_DIR}/Resources/*"
    )
    list(FILTER zui_ios_nested_resources EXCLUDE REGEX "/(README\\.md|\\.DS_Store)$")
    foreach(resource IN LISTS zui_ios_nested_resources)
      file(RELATIVE_PATH relative_resource "${ZUI_IOS_PROJECT_DIR}/Resources" "${resource}")
      get_filename_component(relative_directory "${relative_resource}" DIRECTORY)
      if(relative_directory STREQUAL "")
        set(resource_destination "Resources")
      else()
        set(resource_destination "Resources/${relative_directory}")
      endif()
      set_source_files_properties("${resource}" PROPERTIES
        MACOSX_PACKAGE_LOCATION "${resource_destination}"
      )
    endforeach()
    if(zui_ios_root_resources OR zui_ios_nested_resources)
      target_sources(zui-host PRIVATE ${zui_ios_root_resources} ${zui_ios_nested_resources})
    endif()

    file(GLOB_RECURSE zui_ios_native_sources CONFIGURE_DEPENDS
      "${ZUI_IOS_PROJECT_DIR}/Sources/*.c"
      "${ZUI_IOS_PROJECT_DIR}/Sources/*.cc"
      "${ZUI_IOS_PROJECT_DIR}/Sources/*.cpp"
      "${ZUI_IOS_PROJECT_DIR}/Sources/*.h"
      "${ZUI_IOS_PROJECT_DIR}/Sources/*.m"
      "${ZUI_IOS_PROJECT_DIR}/Sources/*.mm"
      "${ZUI_IOS_PROJECT_DIR}/Sources/*.swift"
    )
    if(zui_ios_native_sources)
      set(zui_ios_swift_sources ${zui_ios_native_sources})
      list(FILTER zui_ios_swift_sources INCLUDE REGEX "\\.swift$")
      if(zui_ios_swift_sources)
        enable_language(Swift)
      endif()
      target_sources(zui-host PRIVATE ${zui_ios_native_sources})
    endif()

    if(EXISTS "${ZUI_IOS_PROJECT_DIR}/Zui.xcconfig")
      set_target_properties(zui-host PROPERTIES
        XCODE_XCCONFIG "${ZUI_IOS_PROJECT_DIR}/Zui.xcconfig"
      )
    endif()
    if(EXISTS "${ZUI_IOS_PROJECT_DIR}/Zui.cmake")
      include("${ZUI_IOS_PROJECT_DIR}/Zui.cmake")
    endif()
  endif()
endif()

if(ANDROID AND EXISTS "${ZUI_ANDROID_PROJECT_DIR}/Zui.cmake")
  include("${ZUI_ANDROID_PROJECT_DIR}/Zui.cmake")
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
