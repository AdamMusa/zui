# frozen_string_literal: true

require "minitest/autorun"
require "rbconfig"
require_relative "../lib/zui"

class CommandTest < Minitest::Test
  def test_command_uses_argv_without_shell_interpolation
    payload = "$(touch /tmp/zui-must-not-exist);`echo nope`"
    result = Zui::Command.run([RbConfig.ruby, "-e", "print ARGV.fetch(0)", payload])
    assert result.success?
    assert_equal payload, result.stdout
    refute File.exist?("/tmp/zui-must-not-exist")
  end

  def test_command_captures_failure_status_and_stderr
    result = Zui::Command.run([RbConfig.ruby, "-e", "warn 'bad'; exit 7"])
    refute result.success?
    assert_equal 7, result.exitstatus
    assert_equal ["bad"], result.stderr.lines(chomp: true)
  end

  def test_command_timeout_terminates_the_child
    assert_raises(Zui::CommandTimeout) do
      Zui::Command.run([RbConfig.ruby, "-e", "sleep 5"], timeout: 0.02)
    end
  end

  def test_command_output_is_bounded
    error = assert_raises(Zui::CommandOutputLimit) do
      Zui::Command.run([RbConfig.ruby, "-e", "print 'x' * 4096"], max_output_bytes: 1024)
    end
    assert_includes error.message, "exceeded 1024 bytes"
  end
end
