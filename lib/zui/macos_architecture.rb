# frozen_string_literal: true

require "fileutils"
require "tempfile"

module Zui
  module MacOSArchitecture
    FAT_MAGICS = ["\xca\xfe\xba\xbe", "\xca\xfe\xba\xbf", "\xbe\xba\xfe\xca", "\xbf\xba\xfe\xca"].map(&:b).freeze
    ARCHITECTURES = { arm64: "arm64", x86_64: "x86_64" }.freeze

    module_function

    def thin!(root, architecture:, command: Command)
      root = File.expand_path(root)
      target = ARCHITECTURES.fetch(architecture.to_sym) do
        raise ArgumentError, "unsupported macOS bundle architecture: #{architecture}"
      end
      saved = 0
      fat_binaries(root).each do |path|
        architectures = command.run(["lipo", "-archs", path], timeout: 30, max_output_bytes: 16_384)
        unless architectures.success?
          raise ArgumentError, "cannot inspect macOS binary architectures: #{path}: #{architectures.stderr.strip}"
        end
        unless architectures.stdout.split.include?(target)
          raise ArgumentError, "macOS binary does not contain the target #{target} architecture: #{path}"
        end

        original_size = File.size(path)
        original_mode = File.lstat(path).mode & 0o777
        Tempfile.create([".zui-thin-", File.extname(path)], File.dirname(path)) do |temporary|
          temporary.close
          FileUtils.rm_f(temporary.path)
          result = command.run(
            ["lipo", path, "-thin", target, "-output", temporary.path],
            timeout: 120, max_output_bytes: 65_536
          )
          unless result.success? && File.file?(temporary.path)
            raise ArgumentError, "cannot thin macOS binary to #{target}: #{path}: #{result.stderr.strip}"
          end
          FileUtils.chmod(original_mode, temporary.path)
          FileUtils.mv(temporary.path, path)
        end
        saved += original_size - File.size(path)
      end
      saved
    end

    def fat_binaries(root)
      Dir[File.join(root, "**", "*")].sort.select do |path|
        File.lstat(path).file? && FAT_MAGICS.include?(File.binread(path, 4))
      rescue EOFError
        false
      end
    end
    private_class_method :fat_binaries
  end
end
