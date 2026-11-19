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

  # Deploying Qt is 92% of a client build and compiling is under two seconds,
  # so what is worth keeping between builds is the staged client. Everything
  # that decides what that staging directory contains has to be in the key, or
  # a build quietly ships a client that no longer matches its source.
  QT = {
    "QT_VERSION" => "6.8.3",
    "QT_INSTALL_QML" => "/opt/qt/6.8.3/macos/qml",
    "QT_INSTALL_PLUGINS" => "/opt/qt/6.8.3/macos/plugins",
    "QT_INSTALL_TRANSLATIONS" => "/opt/qt/6.8.3/macos/translations"
  }.freeze

  def test_the_cache_key_covers_everything_that_decides_what_is_built
    Dir.mktmpdir do |scan|
      File.write(File.join(scan, "Desktop.qml"), "import QtQuick\n")
      baseline = builder.send(:client_cache_key, QT, scan)

      assert_equal baseline, builder.send(:client_cache_key, QT, scan),
                   "the same inputs gave two different keys"

      File.write(File.join(scan, "Desktop.qml"), "import QtQuick\nimport QtMultimedia\n")
      refute_equal baseline, builder.send(:client_cache_key, QT, scan),
                   "a changed QML tree has to change the key: -qmldir decides what is deployed"

      File.write(File.join(scan, "Desktop.qml"), "import QtQuick\n")
      assert_equal baseline, builder.send(:client_cache_key, QT, scan),
                   "putting the QML tree back has to give the key back"

      refute_equal baseline, builder.send(:client_cache_key, QT.merge("QT_VERSION" => "6.9.0"), scan)
      refute_equal baseline, builder.send(:client_cache_key, QT.merge("QT_INSTALL_QML" => "/elsewhere"), scan)

      other = Zui::ClientBuilder.new(platform: Zui::Platform.new(os: :macos, arch: :arm64))

      refute_equal baseline, other.send(:client_cache_key, QT, scan),
                   "two platforms cannot share a client"
    end
  end

  # The native sources are what the client is compiled from, so a change to any
  # of them has to be a cache miss. This is the same set Client#runtime_contract
  # hashes when it decides whether a downloaded client is still the right one.
  def test_the_cache_key_follows_the_native_sources
    Dir.mktmpdir do |scan|
      Dir.mktmpdir do |framework|
        FileUtils.mkdir_p(File.join(framework, "native"))
        Zui::Client::RUNTIME_CONTRACT_FILES.each do |relative|
          File.write(File.join(framework, relative), "// #{relative}\n")
        end
        scoped = Zui::ClientBuilder.new(platform: Zui::Platform.new(os: :linux, arch: :x86_64),
                                        framework_root: framework)
        baseline = scoped.send(:client_cache_key, QT, scan)

        File.write(File.join(framework, "native", "main.cpp"), "// changed\n")

        refute_equal baseline, scoped.send(:client_cache_key, QT, scan),
                     "a change to the native sources has to rebuild the client"
      end
    end
  end

  def test_a_saved_client_comes_back_whole
    Dir.mktmpdir do |directory|
      cache = File.join(directory, "cache")
      stage = File.join(directory, "stage")
      cached = Zui::ClientBuilder.new(platform: Zui::Platform.new(os: :linux, arch: :x86_64),
                                      environment: { "ZUI_CLIENT_CACHE_DIR" => cache, "PATH" => ENV["PATH"] })

      FileUtils.mkdir_p([File.join(stage, "bin"), File.join(stage, "lib")])
      File.write(File.join(stage, "bin", "zui-host"), "the built client")
      File.write(File.join(stage, "lib", "libQt6Core.so.6"), "qt core")
      File.symlink("libQt6Core.so.6", File.join(stage, "lib", "libQt6Core.so"))

      cached.send(:save_client, stage, "k")

      assert_path_exists File.join(cache, "k", "client.tar")
      assert_path_exists File.join(cache, "k", "manifest.json")

      restored = File.join(directory, "restored")

      assert cached.send(:restore_client, restored, "k"), "the client did not come back"
      assert_equal "the built client", File.read(File.join(restored, "bin", "zui-host"), encoding: "UTF-8"),
                   "the executable is part of the client and has to come back with it"
      assert_equal "qt core", File.read(File.join(restored, "lib", "libQt6Core.so.6"), encoding: "UTF-8")
      assert File.symlink?(File.join(restored, "lib", "libQt6Core.so")), "a framework symlink was flattened"
    end
  end

  # An entry with no executable in it is not a client. Better to build than to
  # package whatever that was.
  def test_a_cached_entry_without_an_executable_is_refused
    Dir.mktmpdir do |directory|
      cache = File.join(directory, "cache")
      stage = File.join(directory, "stage")
      cached = Zui::ClientBuilder.new(platform: Zui::Platform.new(os: :linux, arch: :x86_64),
                                      environment: { "ZUI_CLIENT_CACHE_DIR" => cache, "PATH" => ENV["PATH"] })
      FileUtils.mkdir_p(File.join(stage, "lib"))
      File.write(File.join(stage, "lib", "libQt6Core.so.6"), "qt core")
      cached.send(:save_client, stage, "k")

      refute cached.send(:restore_client, File.join(directory, "restored"), "k")
    end
  end

  # Every client that is packaged is checked for the forbidden WebEngine
  # payload. One assembled from a cache has to be checked too, or a corrupted
  # entry would walk straight past the only guard there is.
  def test_a_cached_client_is_still_checked_for_forbidden_browser_files
    Dir.mktmpdir do |directory|
      cache = File.join(directory, "cache")
      stage = File.join(directory, "stage")
      cached = Zui::ClientBuilder.new(platform: Zui::Platform.new(os: :linux, arch: :x86_64),
                                      environment: { "ZUI_CLIENT_CACHE_DIR" => cache, "PATH" => ENV["PATH"] })
      FileUtils.mkdir_p([File.join(stage, "bin"), File.join(stage, "qml", "QtWebEngine")])
      File.write(File.join(stage, "bin", "zui-host"), "the built client")
      File.write(File.join(stage, "qml", "QtWebEngine", "qmldir"), "module QtWebEngine\n")

      cached.send(:save_client, stage, "k")
      restored = File.join(directory, "restored")

      assert cached.send(:restore_client, restored, "k")
      refute_path_exists File.join(restored, "qml", "QtWebEngine"),
                         "a cached client carrying WebEngine must not reach the package"
      assert_path_exists File.join(restored, "bin", "zui-host")
    end
  end

  def test_a_cache_miss_and_a_disabled_cache_both_just_build
    Dir.mktmpdir do |directory|
      cache = File.join(directory, "cache")
      enabled = Zui::ClientBuilder.new(platform: Zui::Platform.new(os: :linux, arch: :x86_64),
                                       environment: { "ZUI_CLIENT_CACHE_DIR" => cache, "PATH" => ENV["PATH"] })

      refute enabled.send(:restore_client, File.join(directory, "a"), "missing"),
             "a key that was never saved cannot restore"

      off = Zui::ClientBuilder.new(platform: Zui::Platform.new(os: :linux, arch: :x86_64),
                                   environment: { "ZUI_CLIENT_CACHE_DIR" => cache, "ZUI_CLIENT_CACHE" => "0",
                                                  "PATH" => ENV["PATH"] })

      refute off.send(:client_cache_enabled?), "ZUI_CLIENT_CACHE=0 has to turn it off"
      refute off.send(:restore_client, File.join(directory, "b"), "missing")
    end
  end

  # One definition of where Zui caches things, shared with the installed
  # clients, so the two cannot drift apart.
  def test_the_client_cache_sits_beside_the_installed_clients
    shared = Zui::Client.new(platform: Zui::Platform.new(os: :linux, arch: :x86_64),
                             environment: { "HOME" => "/home/probe" }).cache_root
    beside = Zui::ClientBuilder.new(platform: Zui::Platform.new(os: :linux, arch: :x86_64),
                                    environment: { "HOME" => "/home/probe" }).send(:client_cache_root)

    assert_equal File.join(shared, "zui", "client-builds"), beside

    override = Zui::ClientBuilder.new(platform: Zui::Platform.new(os: :linux, arch: :x86_64),
                                      environment: { "ZUI_CLIENT_CACHE_DIR" => "/tmp/elsewhere" })

    assert_equal "/tmp/elsewhere", override.send(:client_cache_root)
  end

  private

  def builder
    @builder ||= Zui::ClientBuilder.new(platform: Zui::Platform.new(os: :linux, arch: :x86_64))
  end

end
