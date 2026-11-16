# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/zui"

class QtModulesTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  MOBILE_TARGETS = %w[ios android].freeze
  # Imports that resolve inside the framework itself rather than to a Qt QML module.
  QT_IMPORT = /\A(?:QML|Qt)/

  def framework_imports
    Zui::QtModules.imported_by(ROOT).select { |name, _sources| name.match?(QT_IMPORT) }
  end

  def test_registry_describes_every_module_with_a_consistent_shape
    assert_operator Zui::QtModules.all.size, :>, 60
    assert_equal Zui::QtModules.names, Zui::QtModules.names.uniq
    assert_equal "6.8.3", Zui::QtModules.qt_version

    Zui::QtModules.all.each do |entry|
      assert_match(QT_IMPORT, entry.qml_module)
      assert_empty entry.targets - Zui::QtModules::TARGETS, entry.qml_module
      refute_empty entry.targets, entry.qml_module
      assert_equal "Qt6::#{entry.cmake_component}", entry.link_target if entry.linkable?
      assert_empty entry.unavailable.keys - Zui::QtModules::TARGETS, entry.qml_module
    end
  end

  # The registry is what makes a Qt module linkable on iOS and Android, so an adapter that imports
  # an unregistered module would build on the host and silently lose its types on a device.
  def test_every_qt_module_the_framework_imports_is_registered
    unregistered = framework_imports.reject { |name, _sources| Zui::QtModules.registered?(name) }

    assert_empty unregistered.transform_values { |sources| sources.first.delete_prefix("#{ROOT}/") },
                 "add the module to native/qt-modules.json with `rake qt:modules`"
  end

  def test_every_qt_module_the_framework_imports_reaches_both_mobile_targets
    unreachable = framework_imports.keys.flat_map do |name|
      entry = Zui::QtModules.fetch(name)
      MOBILE_TARGETS.reject { |target| entry.available_on?(target) }.map { |target| "#{name} (#{target})" }
    end

    assert_empty unreachable - ["QtQuick.Pdf (android)"]
  end

  # A module that cannot reach a target has to say why; `zui_link_qt_modules()` repeats the reason
  # when a build keeps an adapter that imports it.
  def test_modules_missing_from_a_mobile_target_record_the_reason
    undocumented = Zui::QtModules.all.flat_map do |entry|
      MOBILE_TARGETS.reject { |target| entry.available_on?(target) || entry.unavailable_reason(target) }
                    .map { |target| "#{entry.qml_module} (#{target})" }
    end

    assert_empty undocumented
  end

  def test_mobile_setup_installs_the_sdk_add_on_of_every_registered_module
    {
      "ios" => Zui::Mobile::Setup::QT_IOS_MODULES,
      "android" => Zui::Mobile::Setup::QT_ANDROID_MODULES
    }.each do |target, installed|
      missing = Zui::QtModules.add_on_sdk_modules(target) - installed

      assert_empty missing, "Zui::Mobile::Setup does not install #{missing.join(', ')} for #{target}"
    end
  end

  def test_pdf_is_documented_as_an_ios_only_mobile_module
    pdf = Zui::QtModules.fetch("QtQuick.Pdf")

    assert pdf.available_on?(:ios)
    refute pdf.available_on?(:android)
    assert_includes pdf.unavailable_reason("android"), "no Android build of Qt PDF"
    assert_equal "qtpdf", pdf.sdk_module
  end

  def test_android_permissions_are_recorded_for_protected_modules
    assert_includes Zui::QtModules.fetch("QtMultimedia").android_permissions,
                    "android.permission.CAMERA"
    assert_includes Zui::QtModules.fetch("QtLocation").android_permissions,
                    "android.permission.ACCESS_FINE_LOCATION"
    assert_empty Zui::QtModules.fetch("QtQuick.Layouts").android_permissions
    assert_equal ["android.permission.ACCESS_FINE_LOCATION"],
                 Zui::QtModules.android_permissions_for(%w[QtQuick.Layouts QtPositioning])
  end

  def test_modules_that_need_native_initialization_name_their_compile_definition
    native = Zui::QtModules.all.select(&:native_initialization?)
    host = File.read(File.join(ROOT, "native", "main.cpp"))

    assert_equal %w[QtQuick.VirtualKeyboard QtWebView], native.map(&:qml_module).sort
    native.each { |entry| assert_includes host, entry.native_initialization }
  end

  def test_the_native_build_wires_qt_modules_from_the_registry
    cmake = File.read(File.join(ROOT, "native", "CMakeLists.txt"))
    wiring = File.read(File.join(ROOT, "native", "ZuiQtModules.cmake"))

    assert_includes cmake, 'include("${CMAKE_CURRENT_SOURCE_DIR}/ZuiQtModules.cmake")'
    assert_includes cmake, 'zui_link_qt_modules(zui-host FRAMEWORK_ROOT "${ZUI_FRAMEWORK_ROOT}")'
    assert_includes wiring, "qt-modules.json"
    assert_includes wiring, "zui_qt_collect_qml_imports"
    assert_includes wiring, "target_link_libraries(${target} PRIVATE ${link_target})"
    assert_includes wiring, "cannot work on ${ZUI_QT_PLATFORM}"
  end

  def test_the_registry_ships_with_the_gem
    specification = Gem::Specification.load(File.join(ROOT, "zui.gemspec"))

    assert_includes specification.files, "native/qt-modules.json"
    assert_includes specification.files, "native/ZuiQtModules.cmake"
    assert_includes specification.files, "lib/zui/qt_modules.rb"
  end
end
