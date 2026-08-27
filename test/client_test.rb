# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require_relative "../lib/zui"
require_relative "support/client_fixture"

class ClientTest < Minitest::Test
  def test_native_build_recipe_is_part_of_the_runtime_contract
    assert_includes Zui::Client::RUNTIME_CONTRACT_FILES, "native/CMakeLists.txt"
  end

  def test_uses_native_user_cache_roots_on_each_platform
    Dir.mktmpdir do |home|
      linux = Zui::Client.new(
        platform: Zui::Platform.new(os: :linux, arch: :x86_64),
        environment: { "HOME" => home, "XDG_CACHE_HOME" => File.join(home, "xdg") }
      )
      macos = Zui::Client.new(
        platform: Zui::Platform.new(os: :macos, arch: :arm64), environment: { "HOME" => home }
      )
      windows = Zui::Client.new(
        platform: Zui::Platform.new(os: :windows, arch: :x86_64),
        environment: { "HOME" => home, "LOCALAPPDATA" => File.join(home, "Local") }
      )

      assert_equal File.join(home, "xdg", "zui", "clients", Zui::VERSION, "linux-x86_64"), linux.root
      assert_equal File.join(home, "Library", "Caches", "zui", "clients", Zui::VERSION, "macos-arm64"), macos.root
      assert_equal File.join(home, "Local", "zui", "clients", Zui::VERSION, "windows-x86_64"), windows.root
    end
  end

  def test_configure_installs_a_versioned_verified_client
    Dir.mktmpdir do |directory|
      platform = Zui::Platform.new(os: :linux, arch: :x86_64)
      source = ClientFixture.create(File.join(directory, "source"), platform:)
      archive = ClientFixture.archive(source, File.join(directory, "client.tar.gz"))
      client = client_for(platform, directory, archive)

      installed = client.configure!

      assert_equal File.join(directory, "cache", "zui", "clients", Zui::VERSION, platform.id), installed
      assert client.configured?
      assert_equal File.join(installed, "bin", "zui-host"), client.executable
      environment = client.environment({ "PATH" => "/usr/bin", "LD_LIBRARY_PATH" => "/existing" })
      assert_equal [File.join(installed, "lib"), "/existing"].join(File::PATH_SEPARATOR),
                   environment.fetch("LD_LIBRARY_PATH")
      assert_equal "/usr/bin", environment.fetch("PATH")
      refute File.exist?(File.join(installed, "app"))
      refute File.exist?(File.join(installed, "lib", "zui.rb"))
    end
  end

  def test_configure_rejects_a_checksum_mismatch
    Dir.mktmpdir do |directory|
      platform = Zui::Platform.new(os: :linux, arch: :x86_64)
      source = ClientFixture.create(File.join(directory, "source"), platform:)
      archive = ClientFixture.archive(source, File.join(directory, "client.tar.gz"))
      File.write("#{archive}.sha256", "#{'0' * 64}  client.tar.gz\n")
      client = client_for(platform, directory, archive)

      error = assert_raises(ArgumentError) { client.configure! }
      assert_includes error.message, "checksum mismatch"
      refute client.configured?
    end
  end

  def test_configure_rejects_archive_traversal
    Dir.mktmpdir do |directory|
      archive = File.join(directory, "client.tar.gz")
      buffer = StringIO.new("".b)
      Gem::Package::TarWriter.new(buffer) do |tar|
        tar.add_file("../escaped", 0o644) { |io| io.write("no") }
      end
      Zlib::GzipWriter.open(archive) { |gzip| gzip.write(buffer.string) }
      File.write("#{archive}.sha256", "#{Digest::SHA256.file(archive).hexdigest}\n")
      platform = Zui::Platform.new(os: :linux, arch: :x86_64)

      error = assert_raises(ArgumentError) { client_for(platform, directory, archive).configure! }
      assert_includes error.message, "unsafe archive entry"
      refute File.exist?(File.join(directory, "escaped"))
    end
  end

  def test_configure_rejects_the_wrong_platform
    Dir.mktmpdir do |directory|
      requested = Zui::Platform.new(os: :macos, arch: :arm64)
      source = ClientFixture.create(File.join(directory, "source"),
                                    platform: Zui::Platform.new(os: :linux, arch: :x86_64))
      archive = ClientFixture.archive(source, File.join(directory, "client.tar.gz"))

      error = assert_raises(ArgumentError) { client_for(requested, directory, archive).configure! }
      assert_includes error.message, "invalid Zui client platform"
    end
  end

  def test_rejects_a_native_client_built_for_an_older_runtime_contract
    Dir.mktmpdir do |directory|
      platform = Zui::Platform.new(os: :linux, arch: :x86_64)
      root = ClientFixture.create(File.join(directory, "client"), platform:)
      manifest_path = File.join(root, "client.json")
      manifest = JSON.parse(File.read(manifest_path))
      manifest["runtime_contract_sha256"] = "0" * 64
      File.write(manifest_path, JSON.pretty_generate(manifest))
      client = Zui::Client.new(platform:, environment: { "ZUI_CLIENT_ROOT" => root })

      refute client.configured?
      error = assert_raises(ArgumentError) { client.manifest }
      assert_includes error.message, "runtime_contract_sha256"
    end
  end

  def test_invalid_explicit_client_root_is_never_replaced
    Dir.mktmpdir do |directory|
      root = File.join(directory, "mine")
      FileUtils.mkdir_p(root)
      File.write(File.join(root, "personal.txt"), "keep")
      platform = Zui::Platform.new(os: :linux, arch: :x86_64)
      client = Zui::Client.new(platform:, environment: { "ZUI_CLIENT_ROOT" => root })

      assert_raises(ArgumentError) { client.configure! }
      assert_equal "keep", File.read(File.join(root, "personal.txt"))
    end
  end

  private

  def client_for(platform, directory, archive)
    Zui::Client.new(platform:, cache_root: File.join(directory, "cache"), environment: {
      "HOME" => directory,
      "ZUI_CLIENT_ARCHIVE" => archive,
      "ZUI_CLIENT_CHECKSUM" => "#{archive}.sha256"
    })
  end
end
