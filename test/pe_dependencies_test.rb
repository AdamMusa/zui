# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require_relative "../lib/zui"
require_relative "support/pe_fixture"

class PEDependenciesTest < Minitest::Test
  def test_reads_a_deterministic_pe_import_table
    Dir.mktmpdir do |directory|
      binary = File.join(directory, "ruby.exe")
      File.binwrite(binary, PEFixture.binary("RUBY.DLL", "KERNEL32.dll", "RUBY.DLL"))

      assert_equal %w[RUBY.DLL KERNEL32.dll], Zui::PEDependencies.imports(binary)
    end
  end

  def test_distinguishes_valid_empty_imports_from_an_unreadable_binary
    Dir.mktmpdir do |directory|
      valid = File.join(directory, "valid.exe")
      invalid = File.join(directory, "invalid.exe")
      File.binwrite(valid, PEFixture.binary)
      File.binwrite(invalid, "not a PE image")

      assert_equal [], Zui::PEDependencies.imports(valid)
      assert_nil Zui::PEDependencies.imports(invalid)
    end
  end
end
