# Generic Qt QML module wiring for Zui application targets.
#
# `native/qt-modules.json` is the single source of truth for every public Qt QML module: the CMake
# component that provides it, the QML plugin the Qt import scanner resolves it to, the SDK add-on
# that installs it, the mobile targets that ship it and the Android permissions it declares.
# `lib/zui/qt_modules.rb` reads the same document, so a Qt module becomes linkable on iOS and
# Android by adding one registry entry rather than editing CMake, Gradle, the tree shaker and the
# mobile setup separately.
#
# `zui_link_qt_modules()` scans the QML tree that is about to be compiled into the application
# resource, looks every import up in the registry and then
#
#   * fails with the recorded reason when the module does not exist for this target,
#   * fails with an actionable message when the module exists but is not installed,
#   * links the module's library so Android deployment and iOS static linking both see it,
#   * defines ZUI_USES_<MODULE> for the modules `native/main.cpp` initializes natively,
#   * restricts the module's backend plugins on static (iOS) builds to the mobile implementations.
#
# Adapters that import nothing new need no registry change at all: Qt's own import scanner keeps
# resolving them, and this file only makes the result explicit and verifiable.

# Collects every `import <Module>` found in the QML tree under `root`.
# `out_imports` receives the module names, `out_sources` the first file that imports each of them,
# at the same list index.
function(zui_qt_collect_qml_imports out_imports out_sources root)
  set(imports "")
  set(sources "")
  if(IS_DIRECTORY "${root}")
    file(GLOB_RECURSE qml_files CONFIGURE_DEPENDS "${root}/*.qml")
    foreach(qml_file IN LISTS qml_files)
      file(STRINGS "${qml_file}" import_lines REGEX "^[ \t]*import[ \t]+[A-Za-z]")
      foreach(import_line IN LISTS import_lines)
        string(REGEX MATCH "^[ \t]*import[ \t]+([A-Za-z][A-Za-z0-9_.]*)" matched "${import_line}")
        if(CMAKE_MATCH_1 AND NOT CMAKE_MATCH_1 IN_LIST imports)
          list(APPEND imports "${CMAKE_MATCH_1}")
          list(APPEND sources "${qml_file}")
        endif()
      endforeach()
    endforeach()
  endif()
  set(${out_imports} "${imports}" PARENT_SCOPE)
  set(${out_sources} "${sources}" PARENT_SCOPE)
endfunction()

# Reads one optional string member, leaving `out_var` empty when the member is absent.
function(zui_qt_json_value out_var document)
  string(JSON value ERROR_VARIABLE json_error GET "${document}" ${ARGN})
  if(json_error OR value STREQUAL "NOTFOUND")
    set(value "")
  endif()
  set(${out_var} "${value}" PARENT_SCOPE)
endfunction()

function(zui_qt_json_list out_var document)
  zui_qt_json_value(array "${document}" ${ARGN})
  set(values "")
  if(NOT array STREQUAL "")
    string(JSON count ERROR_VARIABLE json_error LENGTH "${array}")
    if(NOT json_error AND count GREATER 0)
      math(EXPR last "${count} - 1")
      foreach(index RANGE 0 ${last})
        string(JSON value GET "${array}" ${index})
        list(APPEND values "${value}")
      endforeach()
    endif()
  endif()
  set(${out_var} "${values}" PARENT_SCOPE)
endfunction()

function(zui_link_qt_modules target)
  cmake_parse_arguments(ZUI_QT "" "FRAMEWORK_ROOT;REGISTRY;PLATFORM" "" ${ARGN})
  if(NOT ZUI_QT_REGISTRY)
    set(ZUI_QT_REGISTRY "${CMAKE_CURRENT_LIST_DIR}/qt-modules.json")
  endif()
  if(NOT EXISTS "${ZUI_QT_REGISTRY}")
    message(FATAL_ERROR "Zui Qt module registry not found: ${ZUI_QT_REGISTRY}")
  endif()
  if(NOT ZUI_QT_PLATFORM)
    if(IOS)
      set(ZUI_QT_PLATFORM "ios")
    elseif(ANDROID)
      set(ZUI_QT_PLATFORM "android")
    else()
      set(ZUI_QT_PLATFORM "host")
    endif()
  endif()

  zui_qt_collect_qml_imports(qml_imports qml_import_sources "${ZUI_QT_FRAMEWORK_ROOT}")
  if(NOT qml_imports)
    return()
  endif()

  file(READ "${ZUI_QT_REGISTRY}" registry)
  string(JSON module_count LENGTH "${registry}" modules)
  if(module_count EQUAL 0)
    return()
  endif()

  set(linked_modules "")
  set(unregistered_imports "${qml_imports}")
  math(EXPR last_module "${module_count} - 1")
  foreach(module_index RANGE 0 ${last_module})
    string(JSON entry GET "${registry}" modules ${module_index})
    string(JSON qml_module GET "${entry}" qml_module)
    list(FIND qml_imports "${qml_module}" import_index)
    list(REMOVE_ITEM unregistered_imports "${qml_module}")
    if(import_index EQUAL -1)
      continue()
    endif()
    list(GET qml_import_sources ${import_index} import_source)

    zui_qt_json_value(unavailable_reason "${entry}" unavailable ${ZUI_QT_PLATFORM})
    zui_qt_json_list(module_targets "${entry}" targets)
    if(NOT unavailable_reason STREQUAL "" OR NOT ZUI_QT_PLATFORM IN_LIST module_targets)
      if(unavailable_reason STREQUAL "")
        set(unavailable_reason "the Qt ${ZUI_QT_PLATFORM} SDK does not ship this module")
      endif()
      message(FATAL_ERROR
        "${import_source} imports ${qml_module}, which cannot work on ${ZUI_QT_PLATFORM}: "
        "${unavailable_reason}"
      )
    endif()

    zui_qt_json_value(component "${entry}" cmake_component)
    zui_qt_json_value(link_target "${entry}" link_target)
    zui_qt_json_value(sdk_module "${entry}" sdk_module)
    if(component STREQUAL "" OR link_target STREQUAL "")
      continue()
    endif()

    if(NOT TARGET ${link_target})
      find_package(Qt6 6.8 QUIET COMPONENTS ${component})
    endif()
    if(NOT TARGET ${link_target})
      set(install_hint "reinstall the Qt ${ZUI_QT_PLATFORM} SDK")
      if(NOT sdk_module STREQUAL "")
        set(install_hint "run `zui mobile --fix` to install the ${sdk_module} add-on")
      endif()
      message(FATAL_ERROR
        "${import_source} imports ${qml_module}, which needs the Qt component ${component}. "
        "The Qt ${ZUI_QT_PLATFORM} SDK in use does not provide it: ${install_hint}."
      )
    endif()
    target_link_libraries(${target} PRIVATE ${link_target})

    zui_qt_json_value(native_initialization "${entry}" native_initialization)
    if(NOT native_initialization STREQUAL "")
      target_compile_definitions(${target} PRIVATE ${native_initialization}=1)
    endif()
    list(APPEND linked_modules "${qml_module}")
  endforeach()

  list(SORT linked_modules)
  list(JOIN linked_modules ", " linked_summary)
  message(STATUS "Zui Qt modules linked for ${ZUI_QT_PLATFORM}: ${linked_summary}")
  if(unregistered_imports)
    list(FILTER unregistered_imports EXCLUDE REGEX "^(Zui|Theme|Controls|Support|Builtins)")
    list(FILTER unregistered_imports INCLUDE REGEX "^(QML|Qt)")
    if(unregistered_imports)
      list(JOIN unregistered_imports ", " unregistered_summary)
      message(WARNING
        "Zui Qt module registry has no entry for: ${unregistered_summary}. "
        "Add them to native/qt-modules.json (rake qt:modules) so mobile builds stay verifiable."
      )
    endif()
  endif()
endfunction()
