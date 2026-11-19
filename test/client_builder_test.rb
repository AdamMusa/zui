# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require_relative "../lib/zui"
require_relative "../lib/zui/client_builder"

class ClientBuilderTest < Minitest::Test
  ROOT = File.expand_path("..", __dir__)

  def test_macos_qml_plugins_have_one_canonical_runtime_copy
    Dir.mktmpdir do |stage|
      contents = File.join(stage, "zui-host.app", "Contents")
      qml = File.join(contents, "Resources", "qml", "QtQuick")
      duplicate = File.join(contents, "PlugIns", "quick", "libqtquick2plugin.dylib")
      FileUtils.mkdir_p([qml, File.dirname(duplicate)])
      File.write(File.join(qml, "qmldir"), "module QtQuick\nplugin qtquick2plugin\n")
      File.binwrite(duplicate, "qml plugin")
      builder = Zui::ClientBuilder.new(platform: Zui::Platform.new(os: :macos, arch: :arm64))

      builder.send(:install_macos_qml_plugins, stage)

      assert_equal "qml plugin", File.binread(File.join(qml, "libqtquick2plugin.dylib"))
      refute File.exist?(File.join(contents, "PlugIns", "quick"))
    end
  end

  def test_purges_webengine_and_its_browser_only_dependencies
    Dir.mktmpdir do |stage|
      forbidden = [
        "qml/QtWebEngine/libqtwebenginequickplugin.so",
        "qml/QtWebChannel/qmldir",
        "qml/QtPositioning/qmldir",
        "lib/libQt6WebEngineCore.so.6",
        "lib/libQt6WebChannel.so.6",
        "plugins/designer/libqwebengineview.so",
        "plugins/position/libqtposition_geoclue2.so",
        "translations/qtwebengine_locales/en-US.pak"
      ]
      forbidden.each do |relative|
        path = File.join(stage, relative)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, "browser payload")
      end
      desktop_library = File.join(stage, "lib", "libQt6Quick.so.6")
      File.write(desktop_library, "desktop UI")

      builder = Zui::ClientBuilder.new(platform: Zui::Platform.new(os: :linux, arch: :x86_64))
      builder.send(:purge_browser_payload!, stage)

      forbidden.each { |relative| refute File.exist?(File.join(stage, relative)) }
      assert File.file?(desktop_library)
    end
  end

  def test_linux_qml_payload_contains_only_catalog_roots
    Dir.mktmpdir do |directory|
      qml = File.join(directory, "qt", "qml")
      stage = File.join(directory, "stage")
      Zui::ClientBuilder::LINUX_QML_ROOTS.each do |root|
        path = File.join(qml, root)
        FileUtils.mkdir_p(path)
        File.write(File.join(path, "catalog-marker"), root)
      end
      Zui::ClientBuilder::LINUX_QML_EXCLUSIONS.each do |relative|
        path = File.join(qml, relative)
        FileUtils.mkdir_p(path)
        File.write(File.join(path, "unused-marker"), relative)
      end
      FileUtils.mkdir_p(File.join(qml, "UnrelatedDesktopModule"))
      File.write(File.join(qml, "UnrelatedDesktopModule", "unused"), "unused")

      builder.send(:install_linux_qml, stage, "QT_INSTALL_QML" => qml)

      Zui::ClientBuilder::LINUX_QML_ROOTS.each do |root|
        assert File.file?(File.join(stage, "qml", root, "catalog-marker"))
      end
      Zui::ClientBuilder::LINUX_QML_EXCLUSIONS.each do |relative|
        refute File.exist?(File.join(stage, "qml", relative))
      end
      refute File.exist?(File.join(stage, "qml", "UnrelatedDesktopModule"))
    end
  end

  def test_linux_plugin_payload_excludes_designer_and_pdf_plugins
    Dir.mktmpdir do |directory|
      plugins = File.join(directory, "qt", "plugins")
      stage = File.join(directory, "stage")
      Zui::ClientBuilder::LINUX_PLUGIN_DIRECTORIES.each do |name|
        path = File.join(plugins, name)
        FileUtils.mkdir_p(path)
        File.write(File.join(path, "catalog-plugin.so"), name)
      end
      File.write(File.join(plugins, "imageformats", "libqpdf.so"), "pdf")
      FileUtils.mkdir_p(File.join(plugins, "designer"))
      File.write(File.join(plugins, "designer", "unused.so"), "designer")

      builder.send(:install_linux_plugins, stage, "QT_INSTALL_PLUGINS" => plugins)

      assert File.file?(File.join(stage, "plugins", "platforms", "catalog-plugin.so"))
      assert File.file?(File.join(stage, "plugins", "multimedia", "catalog-plugin.so"))
      assert File.file?(File.join(stage, "plugins", "wayland-shell-integration", "catalog-plugin.so"))
      refute File.exist?(File.join(stage, "plugins", "imageformats", "libqpdf.so"))
      refute File.exist?(File.join(stage, "plugins", "designer"))
    end
  end

  def test_linux_runtime_carries_the_direct_ffmpeg_abi
    prefixes = Zui::ClientBuilder::LINUX_PRIVATE_LIBRARY_PREFIXES

    %w[libavcodec libavformat libavutil libswresample libswscale].each do |name|
      assert_includes prefixes, name
    end
  end

  # A client build takes minutes and used to say nothing about where they went,
  # so nobody waiting on one could tell a slow compile from a slow deployment.
  # Measured on macOS arm64 with Qt 6.8.3 the answer is not close: 322.2s of
  # 350.6s is `cmake --install`, which is macdeployqt copying Qt, against 2.4s
  # of actual compiling.
  PHASES = ["install qml", "cmake configure", "cmake build", "cmake install",
            "catalog runtime", "package"].freeze

  def test_the_build_reports_how_long_each_phase_took
    source = File.read(File.join(ROOT, "lib", "zui", "client_builder.rb"), encoding: "UTF-8")

    assert_includes source, "def phase(name)"
    assert_includes source, "Process.clock_gettime(Process::CLOCK_MONOTONIC)"
    assert_includes source, 'warn format("zui client: '

    PHASES.each do |name|
      assert_includes source, %(phase("#{name}")), "the build does not time the #{name} phase"
    end
  end

  # Deploying Qt is 92% of a client build and compiling is 2.4 seconds of it,
  # so what is worth keeping between builds is the deployed tree. Everything
  # that changes what the deployment produces has to be in the key, or a build
  # quietly reuses a payload that no longer matches its source.
  QT = {
    "QT_VERSION" => "6.8.3",
    "QT_INSTALL_QML" => "/opt/qt/6.8.3/macos/qml",
    "QT_INSTALL_PLUGINS" => "/opt/qt/6.8.3/macos/plugins",
    "QT_INSTALL_TRANSLATIONS" => "/opt/qt/6.8.3/macos/translations"
  }.freeze

  def test_the_deployment_key_covers_everything_that_changes_the_payload
    Dir.mktmpdir do |scan|
      File.write(File.join(scan, "Desktop.qml"), "import QtQuick\n")
      baseline = builder.send(:deployment_key, QT, scan)

      assert_equal baseline, builder.send(:deployment_key, QT, scan),
                   "the same inputs gave two different keys"

      File.write(File.join(scan, "Desktop.qml"), "import QtQuick\nimport QtMultimedia\n")
      refute_equal baseline, builder.send(:deployment_key, QT, scan),
                   "a changed QML tree has to change the key: -qmldir decides what is deployed"

      File.write(File.join(scan, "Desktop.qml"), "import QtQuick\n")
      assert_equal baseline, builder.send(:deployment_key, QT, scan),
                   "putting the QML tree back has to give the key back"

      refute_equal baseline, builder.send(:deployment_key, QT.merge("QT_VERSION" => "6.9.0"), scan)
      refute_equal baseline, builder.send(:deployment_key, QT.merge("QT_INSTALL_QML" => "/elsewhere"), scan)

      other = Zui::ClientBuilder.new(platform: Zui::Platform.new(os: :macos, arch: :arm64))

      refute_equal baseline, other.send(:deployment_key, QT, scan),
                   "two platforms cannot share a deployment"
    end
  end

  def test_a_saved_deployment_comes_back_without_the_executable_in_it
    Dir.mktmpdir do |directory|
      cache = File.join(directory, "cache")
      stage = File.join(directory, "stage")
      build = File.join(directory, "build")
      cached = Zui::ClientBuilder.new(platform: Zui::Platform.new(os: :linux, arch: :x86_64),
                                      environment: { "ZUI_CLIENT_CACHE_DIR" => cache, "PATH" => ENV["PATH"] })

      FileUtils.mkdir_p([File.join(stage, "bin"), File.join(stage, "lib"), build])
      File.write(File.join(stage, "bin", "zui-host"), "deployed binary")
      File.write(File.join(stage, "lib", "libQt6Core.so.6"), "qt core")
      File.symlink("libQt6Core.so.6", File.join(stage, "lib", "libQt6Core.so"))
      File.write(File.join(build, "zui-host"), "freshly compiled binary")

      cached.send(:save_deployment, stage, "k")

      assert_path_exists File.join(cache, "k", "payload.tar")
      assert_path_exists File.join(cache, "k", "manifest.json")

      restored = File.join(directory, "restored")
      assert cached.send(:restore_deployment, restored, build, "k"), "the payload did not come back"

      assert_equal "qt core", File.read(File.join(restored, "lib", "libQt6Core.so.6"))
      assert File.symlink?(File.join(restored, "lib", "libQt6Core.so")), "a framework symlink was flattened"
      assert_equal "freshly compiled binary", File.read(File.join(restored, "bin", "zui-host")),
                   "a cache hit must still ship the binary this build compiled"
      assert File.executable?(File.join(restored, "bin", "zui-host"))
    end
  end

  # Every packaged client is checked for the forbidden WebEngine payload. A
  # client assembled from a cache has to be checked too, or a corrupted entry
  # would walk straight past the one guard that exists.
  def test_a_cached_payload_is_still_checked_for_forbidden_browser_files
    Dir.mktmpdir do |directory|
      cache = File.join(directory, "cache")
      stage = File.join(directory, "stage")
      build = File.join(directory, "build")
      cached = Zui::ClientBuilder.new(platform: Zui::Platform.new(os: :linux, arch: :x86_64),
                                      environment: { "ZUI_CLIENT_CACHE_DIR" => cache, "PATH" => ENV["PATH"] })
      FileUtils.mkdir_p([File.join(stage, "bin"), File.join(stage, "qml", "QtWebEngine"), build])
      File.write(File.join(stage, "bin", "zui-host"), "deployed")
      File.write(File.join(stage, "qml", "QtWebEngine", "qmldir"), "module QtWebEngine\n")
      File.write(File.join(build, "zui-host"), "compiled")

      # saving purges it, so the entry itself is clean
      cached.send(:save_deployment, stage, "k")
      restored = File.join(directory, "restored")

      assert cached.send(:restore_deployment, restored, build, "k")
      refute_path_exists File.join(restored, "qml", "QtWebEngine")

      # and an entry that has WebEngine in it — however it got there — is
      # purged on the way out, so what gets packaged is still clean. The
      # guarantee is about what ships, not about rejecting the cache.
      Dir.mktmpdir do |tampered|
        FileUtils.mkdir_p([File.join(tampered, "qml", "QtWebEngine"), File.join(tampered, "bin")])
        File.write(File.join(tampered, "qml", "QtWebEngine", "qmldir"), "module QtWebEngine\n")
        File.write(File.join(tampered, "bin", "keep"), "kept")
        system("tar", "-cpf", File.join(cache, "k", "payload.tar"), "-C", tampered, ".", out: File::NULL)
      end
      again = File.join(directory, "again")

      assert cached.send(:restore_deployment, again, build, "k")
      refute_path_exists File.join(again, "qml", "QtWebEngine"),
                         "a cached payload carrying WebEngine must not reach the package"
      assert_path_exists File.join(again, "bin", "keep")
    end
  end

  def test_a_cache_miss_and_a_disabled_cache_both_just_build
    Dir.mktmpdir do |directory|
      cache = File.join(directory, "cache")
      enabled = Zui::ClientBuilder.new(platform: Zui::Platform.new(os: :linux, arch: :x86_64),
                                       environment: { "ZUI_CLIENT_CACHE_DIR" => cache, "PATH" => ENV["PATH"] })

      refute enabled.send(:restore_deployment, File.join(directory, "a"), directory, "missing"),
             "a key that was never saved cannot restore"

      off = Zui::ClientBuilder.new(platform: Zui::Platform.new(os: :linux, arch: :x86_64),
                                   environment: { "ZUI_CLIENT_CACHE_DIR" => cache, "ZUI_CLIENT_CACHE" => "0",
                                                  "PATH" => ENV["PATH"] })

      refute off.send(:deployment_cache_enabled?), "ZUI_CLIENT_CACHE=0 has to turn it off"
      refute off.send(:restore_deployment, File.join(directory, "b"), directory, "missing")
    end
  end

  # One definition of where Zui caches things, shared with the installed
  # clients, so the two cannot drift apart.
  def test_the_deployment_cache_sits_beside_the_installed_clients
    shared = Zui::Client.new(platform: Zui::Platform.new(os: :linux, arch: :x86_64),
                             environment: { "HOME" => "/home/probe" }).cache_root
    beside = Zui::ClientBuilder.new(platform: Zui::Platform.new(os: :linux, arch: :x86_64),
                                    environment: { "HOME" => "/home/probe" }).send(:deployment_cache_root)

    assert_equal File.join(shared, "zui", "client-deployments"), beside

    override = Zui::ClientBuilder.new(platform: Zui::Platform.new(os: :linux, arch: :x86_64),
                                      environment: { "ZUI_CLIENT_CACHE_DIR" => "/tmp/elsewhere" })

    assert_equal "/tmp/elsewhere", override.send(:deployment_cache_root)
  end

  def test_the_compiled_executable_is_found_in_each_layout
    Dir.mktmpdir do |build|
      linux = Zui::ClientBuilder.new(platform: Zui::Platform.new(os: :linux, arch: :x86_64))
      FileUtils.mkdir_p(build)
      File.write(File.join(build, "zui-host"), "elf")

      assert_equal File.join(build, "zui-host"), linux.send(:built_executable, build)

      macos = Zui::ClientBuilder.new(platform: Zui::Platform.new(os: :macos, arch: :arm64))
      bundle = File.join(build, "zui-host.app", "Contents", "MacOS")
      FileUtils.mkdir_p(bundle)
      File.write(File.join(bundle, "zui-host"), "mach-o")

      assert_equal File.join(bundle, "zui-host"), macos.send(:built_executable, build)
    end
  end

  def test_a_build_without_its_executable_refuses_to_use_a_cached_payload
    Dir.mktmpdir do |build|
      error = assert_raises(ArgumentError) { builder.send(:built_executable, build) }

      assert_includes error.message, "cached deployment"
    end
  end

  private

  def builder
    @builder ||= Zui::ClientBuilder.new(platform: Zui::Platform.new(os: :linux, arch: :x86_64))
  end

end
