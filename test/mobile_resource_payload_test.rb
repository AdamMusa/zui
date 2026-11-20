# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/zui"

# A mobile application loads the framework from a Qt resource rather than from disk, so anything an
# adapter loads at runtime has to be listed in the resource globs of native/CMakeLists.txt. QML
# that is present while the JavaScript library or shader it loads is not produces a component error
# on the device and nothing on the host, which is the hardest kind of gap to notice.
class MobileResourcePayloadTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  # Extensions the QML engine loads from the resource at runtime.
  RUNTIME_EXTENSIONS = %w[.qml .js .qsb].freeze
  PAYLOAD_DIRECTORIES = %w[Components Controls Theme].freeze

  def cmake
    @cmake ||= File.read(File.join(ROOT, "native", "CMakeLists.txt"))
  end

  # The patterns of the resource that carries the framework, as Ruby glob patterns rooted at the
  # framework. CMake's GLOB_RECURSE matches its pattern at any depth below the listed directory.
  def resource_globs
    block = cmake[/file\(GLOB_RECURSE zui_qml_resources.*?\n  \)/m]
    refute_nil block, "native/CMakeLists.txt no longer globs the framework resource"
    block.scan(/"\$\{ZUI_FRAMEWORK_ROOT\}\/([^"]+)"/).flatten.map do |pattern|
      directory, entry = pattern.split("/", 2)
      File.join(ROOT, directory, "**", entry)
    end
  end

  def test_the_mobile_resource_covers_every_runtime_asset_of_the_framework
    globs = resource_globs
    assets = PAYLOAD_DIRECTORIES.flat_map { |directory| Dir[File.join(ROOT, directory, "**", "*")] }
                                .select { |path| File.file?(path) }
                                .select { |path| RUNTIME_EXTENSIONS.include?(File.extname(path)) }
    uncovered = assets.reject do |path|
      globs.any? { |glob| File.fnmatch?(glob, path, File::FNM_PATHNAME) }
    end

    refute_empty assets
    assert_empty uncovered.map { |path| path.delete_prefix("#{ROOT}/") },
                 "add the missing pattern to the zui_qml_resources glob in native/CMakeLists.txt"
  end

  def test_shared_javascript_libraries_and_precompiled_shaders_are_part_of_the_payload
    globs = resource_globs
    script = File.join(ROOT, "Components", "Builtins", "Support", "OptionalModuleState.js")
    shader = File.join(ROOT, "Components", "Builtins", "Shaders", "passthrough.frag.qsb")

    [script, shader].each do |path|
      assert_path_exists path
      assert globs.any? { |glob| File.fnmatch?(glob, path, File::FNM_PATHNAME) },
             "#{path.delete_prefix("#{ROOT}/")} never reaches a mobile build"
    end
  end

  # The tree shaker keeps these files only while the adapters that load them survive, so the
  # resource and the shaker have to agree about which assets exist.
  def test_the_adapters_that_load_those_assets_still_reference_them
    model_view = File.read(File.join(ROOT, "Components", "Builtins", "ModelView3d.qml"))
    shader_effect = File.read(File.join(ROOT, "Components", "Builtins", "ShaderEffect.qml"))

    assert_includes model_view, 'import "Support/OptionalModuleState.js"'
    assert_includes shader_effect, '"Shaders/"'
    assert_includes shader_effect, '".frag.qsb"'
  end
end
