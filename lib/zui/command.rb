# frozen_string_literal: true

require "open3"
require "timeout"

module Zui
  class CommandTimeout < StandardError; end
  class CommandOutputLimit < StandardError; end

  CommandResult = Struct.new(:stdout, :stderr, :status, keyword_init: true) do
    def success? = status.success?
    def exitstatus = status.exitstatus
  end

  module Command
    module_function

    DEFAULT_MAX_OUTPUT_BYTES = 1_048_576

    def run(argv, env: {}, chdir: nil, input: "", timeout: nil, max_output_bytes: DEFAULT_MAX_OUTPUT_BYTES)
      arguments = normalize_argv(argv)
      output_limit = Integer(max_output_bytes)
      raise ArgumentError, "max_output_bytes must be positive" unless output_limit.positive?
      options = {}
      options[:chdir] = File.expand_path(chdir) if chdir
      stdin = stdout = stderr = wait_thread = nil
      Open3.popen3(normalize_env(env), *arguments, **options) do |child_stdin, child_stdout, child_stderr, child_wait|
        stdin, stdout, stderr, wait_thread = child_stdin, child_stdout, child_stderr, child_wait
        stdin.write(input.to_s)
        stdin.close
        stdout_reader = Thread.new { bounded_read(stdout, output_limit) }
        stderr_reader = Thread.new { bounded_read(stderr, output_limit) }
        status = timeout ? Timeout.timeout(Float(timeout)) { wait_thread.value } : wait_thread.value
        stdout_value, stdout_limited = stdout_reader.value
        stderr_value, stderr_limited = stderr_reader.value
        if stdout_limited || stderr_limited
          raise CommandOutputLimit, "command output exceeded #{output_limit} bytes: #{arguments.first}"
        end
        return CommandResult.new(stdout: stdout_value, stderr: stderr_value, status:)
      rescue Timeout::Error
        terminate(wait_thread)
        stdout_reader&.join(1)
        stderr_reader&.join(1)
        raise CommandTimeout, "command timed out after #{timeout}s: #{arguments.first}"
      end
    ensure
      [stdin, stdout, stderr].each { |stream| stream&.close unless stream&.closed? }
    end

    def bounded_read(stream, limit)
      output = +""
      exceeded = false
      loop do
        chunk = stream.readpartial(16_384)
        remaining = limit - output.bytesize
        if remaining.positive?
          output << chunk.byteslice(0, remaining)
          exceeded = true if chunk.bytesize > remaining
        else
          exceeded = true
        end
      end
    rescue EOFError
      [output, exceeded]
    end
    private_class_method :bounded_read

    def normalize_argv(argv)
      raise ArgumentError, "command must be an argv array" unless argv.is_a?(Array) && !argv.empty?
      argv.map do |argument|
        raise ArgumentError, "command arguments must be strings" unless argument.is_a?(String)
        raise ArgumentError, "command arguments cannot contain NUL" if argument.include?("\0")
        argument
      end
    end
    private_class_method :normalize_argv

    def normalize_env(env)
      raise ArgumentError, "command environment must be a hash" unless env.is_a?(Hash)
      env.to_h { |key, value| [key.to_s, value.to_s] }
    end
    private_class_method :normalize_env

    def terminate(wait_thread)
      if RUBY_PLATFORM.match?(/mswin|mingw|cygwin/i)
        Process.kill("KILL", wait_thread.pid)
        wait_thread.value
        return
      end

      Process.kill("TERM", wait_thread.pid)
      Timeout.timeout(1) { wait_thread.value }
    rescue Errno::ESRCH, Errno::ECHILD
      nil
    rescue Timeout::Error
      Process.kill("KILL", wait_thread.pid)
      wait_thread.value
    end
    private_class_method :terminate
  end
end
