# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require_relative "../lib/zui"

class MacOSArchitectureTest < Minitest::Test
  Result = Struct.new(:stdout, :stderr, :successful, keyword_init: true) do
    def success? = successful
  end

  class FakeLipo
    attr_reader :calls

    def initialize(architectures: "x86_64 arm64")
      @architectures = architectures
      @calls = []
    end

    def run(arguments, **)
      @calls << arguments
      return Result.new(stdout: "#{@architectures}\n", stderr: "", successful: true) if arguments[1] == "-archs"

      output = arguments.fetch(arguments.index("-output") + 1)
      File.binwrite(output, "\xcf\xfa\xed\xfe".b + "thin-arm64")
      Result.new(stdout: "", stderr: "", successful: true)
    end
  end

  def test_thins_only_fat_macho_files_to_the_bundle_architecture
    Dir.mktmpdir do |directory|
      fat = File.join(directory, "QtCore")
      plain = File.join(directory, "metadata.json")
      File.binwrite(fat, "\xca\xfe\xba\xbe".b + ("universal" * 20))
      File.write(plain, "metadata")
      FileUtils.chmod(0o755, fat)
      command = FakeLipo.new

      saved = Zui::MacOSArchitecture.thin!(directory, architecture: :arm64, command:)

      assert_operator saved, :>, 0
      assert_equal "\xcf\xfa\xed\xfethin-arm64".b, File.binread(fat)
      assert_equal "metadata", File.read(plain)
      assert_equal 0o755, File.stat(fat).mode & 0o777
      assert_equal 2, command.calls.length
      assert_equal ["lipo", "-archs", fat], command.calls.first
      assert_equal "arm64", command.calls.last[3]
    end
  end

  def test_rejects_a_fat_binary_without_the_target_architecture
    Dir.mktmpdir do |directory|
      fat = File.join(directory, "QtCore")
      original = "\xca\xfe\xba\xbe".b + "x86-only"
      File.binwrite(fat, original)

      error = assert_raises(ArgumentError) do
        Zui::MacOSArchitecture.thin!(
          directory, architecture: :arm64, command: FakeLipo.new(architectures: "x86_64")
        )
      end

      assert_includes error.message, "does not contain the target arm64 architecture"
      assert_equal original, File.binread(fat)
    end
  end
end
