# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require_relative "../lib/zui"

class DistConfigTest < Minitest::Test
  def test_loads_and_validates_the_ruby_distribution_dsl
    with_project do |project|
      write_icon(project, "assets/icon.png", "\x89PNG\r\n\x1a\n".b)
      write_config(project)

      config = Zui::Dist.load(
        project:, platform: Zui::Platform.new(os: :linux, arch: :x86_64)
      )

      assert_equal "Signal Board", config.name
      assert_equal "com.example.signal-board", config.identifier
      assert_equal "1.2.3", config.version
      assert_equal "signal-board", config.package_name
      assert_equal %w[Utility Development], config.categories
      assert_equal File.realpath(File.join(project, "assets", "icon.png")),
                   config.icon_path(project, Zui::Platform.new(os: :linux, arch: :x86_64))
    end
  end

  def test_requires_the_ruby_config_in_the_project_root
    with_project do |project|
      error = assert_raises(ArgumentError) do
        Zui::Dist.load(project:, platform: Zui::Platform.new(os: :linux, arch: :x86_64))
      end

      assert_includes error.message, "config.rb not found"
    end
  end

  def test_rejects_an_icon_outside_the_project
    Dir.mktmpdir do |directory|
      project = File.join(directory, "project")
      FileUtils.mkdir_p(project)
      outside = File.join(directory, "outside.png")
      File.binwrite(outside, "\x89PNG\r\n\x1a\n".b)
      write_config(project, linux_icon: "../outside.png")

      error = assert_raises(ArgumentError) do
        Zui::Dist.load(project:, platform: Zui::Platform.new(os: :linux, arch: :x86_64))
      end

      assert_includes error.message, "must stay inside"
    end
  end

  def test_validates_the_native_icon_format_for_each_platform
    with_project do |project|
      write_icon(project, "assets/icon.icns", "icnsfixture")
      write_config(project)

      config = Zui::Dist.load(
        project:, platform: Zui::Platform.new(os: :macos, arch: :arm64)
      )
      assert_equal File.realpath(File.join(project, "assets", "icon.icns")),
                   config.icon_path(project, Zui::Platform.new(os: :macos, arch: :arm64))
    end
  end

  def test_config_file_must_return_the_dsl_result
    with_project do |project|
      File.write(File.join(project, Zui::Dist::CONFIG_FILE), "{ name: 'Demo' }\n")

      error = assert_raises(ArgumentError) do
        Zui::Dist.load(project:, platform: Zui::Platform.new(os: :linux, arch: :x86_64))
      end

      assert_includes error.message, "must return Zui::Dist.configure"
    end
  end

  private

  def with_project
    Dir.mktmpdir do |directory|
      project = File.join(directory, "project")
      FileUtils.mkdir_p(project)
      yield project
    end
  end

  def write_icon(project, relative, contents)
    path = File.join(project, relative)
    FileUtils.mkdir_p(File.dirname(path))
    File.binwrite(path, contents)
  end

  def write_config(project, linux_icon: "assets/icon.png")
    File.write(File.join(project, Zui::Dist::CONFIG_FILE), <<~RUBY)
      Zui::Dist.configure do
        name "Signal Board"
        identifier "com.example.signal-board"
        version "1.2.3"
        publisher "Example Company <dev@example.com>"
        description "A native signal dashboard."
        license "MIT"
        homepage "https://example.com/signal-board"
        icon linux: #{linux_icon.dump}, macos: "assets/icon.icns", windows: "assets/icon.ico"
        categories "Utility", "Development"
      end
    RUBY
  end
end
