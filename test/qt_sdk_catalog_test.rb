# frozen_string_literal: true

require "minitest/autorun"
require "set"
require_relative "../lib/zui"

# `aqt` installs exactly the add-ons it is handed. A Qt module whose CMake package depends on a
# module nobody asked for fails at find_package() with nothing in the QML error naming the missing
# add-on, so the mobile catalog has to list the dependencies as well as the modules themselves.
class QtSdkCatalogTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  SETUP = Zui::Mobile::Setup
  # Bundled third-party libraries and language-server internals link statically into the module
  # that carries them and never ship as packages of their own.
  INTERNAL_PACKAGE = /\AQt6(?:Bundled_|LanguageServer)/

  def sdk_roots
    {
      "host" => ENV["ZUI_QT_HOST"] || File.join(ROOT, "tmp", "Qt", SETUP::QT_VERSION, "macos"),
      "ios" => ENV["ZUI_QT_IOS"] || File.join(ROOT, "tmp", "Qt", SETUP::QT_VERSION, "ios"),
      "android" => ENV["ZUI_QT_ANDROID"] || File.join(ROOT, "tmp", "Qt", SETUP::QT_VERSION, "android_arm64_v8a")
    }.select { |_target, path| File.directory?(File.join(path, "lib", "cmake")) }
  end

  # Qt6Quick3DRuntimeRender, Qt 3D's RHI renderer and the Qt 5 compatibility effects all declare
  # Qt6ShaderTools, so a catalog without it cannot load QtQuick3D at all - which is why
  # model_view_3d could not work on a device.
  def test_the_mobile_catalog_installs_the_shader_tools_its_modules_depend_on
    assert_includes SETUP::QT_IOS_MODULES, "qtshadertools"
    assert_includes SETUP::QT_ANDROID_MODULES, "qtshadertools"
    assert_includes SETUP::QT_HOST_MODULES, "qtshadertools"
    assert_equal "Qt6ShaderTools", SETUP::QT_MODULE_PACKAGES.fetch("qtshadertools")
  end

  def test_every_catalog_module_has_a_verified_package
    assert_equal SETUP::QT_MOBILE_MODULES.sort, SETUP::QT_MODULE_PACKAGES.keys.sort
    SETUP::QT_MODULE_PACKAGES.each_value { |package| assert_match(/\AQt6[A-Za-z0-9]+\z/, package) }
  end

  # The same walk `rake qt:sdk` performs: a package referenced by a dependency manifest that the
  # SDK does not provide is a module that cannot be found at build time.
  def test_installed_sdks_resolve_every_qt_package_dependency
    roots = sdk_roots
    skip "no installed Qt #{SETUP::QT_VERSION} SDK" if roots.empty?

    roots.each do |target, path|
      cmake = File.join(path, "lib", "cmake")
      available = Dir[File.join(cmake, "Qt6*")].map { |entry| File.basename(entry) }.to_set
      unless available.include?("Qt6ShaderTools")
        skip "the #{target} SDK predates the shader tools catalog entry; run `zui mobile --fix`"
      end

      missing = Dir[File.join(cmake, "**", "*Dependencies.cmake")].flat_map do |manifest|
        text = File.read(manifest, encoding: "UTF-8", invalid: :replace, undef: :replace, replace: "")
        text.scan(/_target_deps\s+"([^"]*)"/).flatten.join(";").scan(/Qt6\w+/).uniq
            .reject { |package| available.include?(package) || package.match?(INTERNAL_PACKAGE) }
      end.uniq.sort

      assert_empty missing, "the #{target} SDK references #{missing.join(', ')} without providing them"
    end
  end
end
