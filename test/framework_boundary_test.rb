# frozen_string_literal: true

require "minitest/autorun"
require_relative "../lib/zui"

class FrameworkBoundaryTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)
  FRAMEWORK_SOURCE_GLOBS = [
    "*.qml",
    "Components/**/*.{qml,js,frag}",
    "Controls/**/*.qml",
    "Theme/**/*.qml",
    "lib/**/*.rb",
    "native/**/*.{cpp,h,mm}",
    "bin/*"
  ].freeze
  SHOWCASE_MARKERS = [
    "examples/",
    "restaurant_drinks",
    "futuristic_dashboard",
    "tesla_drive_dashboard",
    "shader_studio",
    "cardiac_health_monitor",
    "orbital_weather_console",
    "quantum_market_terminal",
    "smart_home_energy",
    "cinematic_music_studio",
    "Table Pour",
    "Pulse Atlas",
    "Lumen Forge",
    "Quantum Market",
    "Habitat One",
    "Tesla Drive Lab",
    "hra-heart",
    "luminous-heart",
    "electric-grand-tourer",
    "vehicle-status-render",
    "smart-living-room",
    "midnight-drift",
    "golden-apollian",
    "procedural-ocean",
    "synthwave-city"
  ].freeze
  ERROR_REPORTING_RENDERERS = {
    image: "Image.qml", animated_image: "AnimatedImage.qml", border_image: "BorderImage.qml",
    avatar: "Avatar.qml", font_loader: "FontLoader.qml", video: "Video.qml", audio: "Audio.qml",
    shader_effect: "ShaderEffect.qml", model_view_3d: "ModelView3d.qml",
    media_player: "MediaPlayer.qml", sound_effect: "SoundEffect.qml", camera: "Camera.qml",
    capture_session: "CaptureSession.qml", audio_input: "AudioInput.qml",
    audio_output: "AudioOutput.qml", screen_capture: "ScreenCapture.qml",
    window_capture: "WindowCapture.qml", media_recorder: "MediaRecorder.qml",
    image_capture: "ImageCapture.qml", loader: "Loader.qml", alert_dialog: "AlertDialog.qml",
    web_view: "WebView.qml",
    tab_button: "TabButton.qml", navigation_rail: "NavigationRail.qml",
    breadcrumb: "Breadcrumb.qml", item_delegate: "ItemDelegate.qml",
    swipe_delegate: "SwipeDelegate.qml", carousel: "Carousel.qml"
  }.freeze

  def test_framework_sources_do_not_depend_on_showcase_code_or_assets
    leaks = framework_source_files.flat_map do |path|
      source = File.binread(path)
      SHOWCASE_MARKERS.filter_map do |marker|
        relative_path(path) if source.include?(marker)
      end
    end

    assert_empty leaks.uniq.sort
  end

  def test_model_view_is_domain_neutral
    schema = Zui::COMPONENTS.fetch(:model_view_3d).first
    scene = File.read(File.join(ROOT, "Components/Builtins/Support/ModelView3dScene.qml"))

    assert_empty schema & %i[bpm pulse pulse_scale fallback_source fallback_text fallback_fill_mode
                              prefer_3d fallback_while_loading]
    refute_match(/\b(?:bpm|beatAmount|pulse_scale|heart)\b/i, scene)
  end

  def test_components_never_expose_or_render_silent_fallbacks
    fallback_properties = Zui::COMPONENTS.flat_map do |name, (properties, _events, _container)|
      properties.grep(/\Afallback_/).map { |property| "#{name}.#{property}" }
    end
    model_view = File.read(File.join(ROOT, "Components/Builtins/ModelView3d.qml"))
    avatar = File.read(File.join(ROOT, "Components/Builtins/Avatar.qml"))

    assert_empty fallback_properties
    refute_includes model_view, "Image {"
    refute_includes model_view, "fallback"
    assert_includes avatar, 'visible: avatarRoot.avatarSource === ""'
    refute_includes avatar, "avatarImage.status !== Image.Ready"
  end

  def test_declared_component_types_fail_instead_of_becoming_another_type
    builder = Zui::Builder.instance_method(:image).source_location
    router = File.read(File.join(ROOT, "ControlNode.qml"))

    refute_nil builder
    assert_raises(ArgumentError) { Zui::Application.new { app { component(:not_a_component) } } }
    refute_nil Zui::Builder.instance_method(:web_view).source_location
    assert_includes router, "sourceComponent: null"
    assert_includes router, "builtInSource(node.type)"
    assert_includes router, 'builtIn ? builtInSource(node.type) : bridge.componentSource(node.type)'
    refute_match(/node\.type === "model_view_3d"[^\n]+imageComponent/, router)
  end


  def test_mobile_webview_is_linked_and_initialized_only_when_tree_shaking_keeps_it
    cmake = File.read(File.join(ROOT, "native", "CMakeLists.txt"))
    host = File.read(File.join(ROOT, "native", "main.cpp"))

    assert_includes cmake, 'EXISTS "${ZUI_FRAMEWORK_ROOT}/Components/Builtins/WebView.qml"'
    assert_includes cmake, "target_link_libraries(zui-host PRIVATE Qt6::WebView)"
    assert_includes cmake, "INCLUDE_BY_TYPE multimedia Qt6::QDarwinMediaPlugin"
    assert_includes cmake, "INCLUDE_BY_TYPE texttospeech Qt6::QTextToSpeechDarwinPlugin"
    assert_includes cmake, "INCLUDE_BY_TYPE position Qt6::QGeoPositionInfoSourceFactoryCLPlugin"
    assert_includes cmake, "INCLUDE_BY_TYPE sensors Qt6::IOSSensorPlugin"
    assert_includes cmake, "INCLUDE_BY_TYPE webview Qt6::QDarwinWebViewPlugin"
    assert_includes host, "QtWebView::initialize();"
    assert_includes host, "ZUI_USES_WEBVIEW"
    assert_includes host, 'qputenv("QML_DISABLE_DISK_CACHE", QByteArrayLiteral("1"));'
    assert_includes host, 'QStandardPaths::writableLocation(QStandardPaths::CacheLocation)'
    assert_includes host, "QDir(qmlCache).removeRecursively();"
  end

  def test_mobile_virtual_keyboard_is_linked_and_activated_only_when_tree_shaking_keeps_it
    cmake = File.read(File.join(ROOT, "native", "CMakeLists.txt"))
    host = File.read(File.join(ROOT, "native", "main.cpp"))

    assert_includes cmake, 'EXISTS "${ZUI_FRAMEWORK_ROOT}/Components/Builtins/VirtualKeyboard.qml"'
    assert_includes cmake, "target_link_libraries(zui-host PRIVATE Qt6::VirtualKeyboard)"
    assert_includes host, "ZUI_USES_VIRTUAL_KEYBOARD"
    assert_includes host, 'qputenv("QT_IM_MODULE", QByteArrayLiteral("qtvirtualkeyboard"));'
  end

  def test_component_and_resource_failures_use_the_framework_error_channel
    router = File.read(File.join(ROOT, "ControlNode.qml"))
    service = File.read(File.join(ROOT, "Service.qml"))

    assert_includes router, "function componentError(code, message, payload)"
    assert_includes router, "status === Loader.Error"
    assert_includes service, "function reportComponentError(surfaceName, controlId, componentType, code, message)"
    ERROR_REPORTING_RENDERERS.each do |component, renderer|
      source = File.read(File.join(ROOT, "Components/Builtins", renderer))
      assert_includes source, "componentError", "#{renderer} does not report failures"
      assert_includes Zui::COMPONENTS.fetch(component)[1], :error,
                      "#{component} does not expose its failures to Ruby"
    end
  end

  def test_gem_excludes_examples_and_release_only_builders
    specification = Gem::Specification.load(File.join(ROOT, "zui.gemspec"))

    refute_nil specification
    assert_empty specification.files.grep(%r{\Aexamples(?:/|\z)})
    assert_empty specification.files.grep(/(?:\A|\/)examples(?:\/|\z)/)
    assert_empty specification.files.grep(%r{\Avendor/})
    assert_empty specification.files.grep(%r{\Alib/zui/client_(?:builder|packager)\.rb\z})
    assert_includes specification.files, "native/CMakeLists.txt"
    assert_includes specification.files, "native/ZuiEmbeddedRuntime.cpp"
    assert_includes specification.files, "runtime/mruby/ios_simulator_build_config.rb"
    assert_includes specification.files, "runtime/mruby/android_build_config.rb"
  end

  def test_core_has_no_omarchy_or_quickshell_dependency
    coupled = framework_source_files.select do |path|
      File.binread(path).match?(/\b(?:OmarchyUI|Quickshell|OMARCHY_UI)\b/)
    end

    assert_empty coupled.map { |path| relative_path(path) }
  end

  private

  def framework_source_files
    FRAMEWORK_SOURCE_GLOBS.flat_map { |glob| Dir[File.join(ROOT, glob)] }
      .select { |path| File.file?(path) }
      .uniq
  end

  def relative_path(path)
    path.delete_prefix("#{ROOT}/")
  end
end
