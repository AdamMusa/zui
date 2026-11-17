# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "rubygems/package"
require "stringio"
require "zlib"

module ClientFixture
  module_function

  def create(root, platform:, version: Zui::VERSION, environment: default_environment(platform))
    FileUtils.mkdir_p(File.join(root, "bin"))
    executable = platform.windows? ? "bin/zui-host.exe" : "bin/zui-host"
    File.write(File.join(root, executable), "native host")
    FileUtils.chmod(0o755, File.join(root, executable))
    environment.values.flatten.each do |path|
      FileUtils.mkdir_p(File.join(root, path))
      File.write(File.join(root, path, ".fixture"), "runtime")
    end
    File.write(File.join(root, "client.json"), JSON.pretty_generate(
      "format" => 1,
      "framework" => "zui",
      "client_version" => version,
      "platform" => platform.id,
      "runtime_contract_sha256" => Zui::Client.runtime_contract,
      "bundle_capable" => true,
      "payload" => %w[native-host qt-engine],
      "executable" => executable,
      "required_paths" => ([File.dirname(executable)] + environment.values.flatten).uniq,
      "environment" => environment
    ))
    root
  end

  def archive(source, destination)
    buffer = StringIO.new("".b)
    Gem::Package::TarWriter.new(buffer) do |tar|
      add_tree(tar, source, source)
    end
    Zlib::GzipWriter.open(destination) { |gzip| gzip.write(buffer.string) }
    File.write("#{destination}.sha256", "#{Digest::SHA256.file(destination).hexdigest}  #{File.basename(destination)}\n")
    destination
  end

  def add_tree(tar, root, current)
    Dir.children(current).sort.each do |name|
      path = File.join(current, name)
      relative = path.delete_prefix("#{root}/")
      stat = File.stat(path)
      if stat.directory?
        tar.mkdir(relative, stat.mode)
        add_tree(tar, root, path)
      else
        tar.add_file(relative, stat.mode) { |io| io.write(File.binread(path)) }
      end
    end
  end

  def default_environment(platform)
    if platform.windows?
      return {
        "PATH" => ["bin"],
        "QT_PLUGIN_PATH" => ["plugins"],
        "QML_IMPORT_PATH" => ["qml"],
        "QML2_IMPORT_PATH" => ["qml"]
      }
    end
    return {} if platform.macos?

    {
      "LD_LIBRARY_PATH" => ["lib"],
      "QT_PLUGIN_PATH" => ["plugins"],
      "QML_IMPORT_PATH" => ["qml"],
      "QML2_IMPORT_PATH" => ["qml"]
    }
  end
end
