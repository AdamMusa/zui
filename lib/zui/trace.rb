# frozen_string_literal: true

module Zui
  # Startup spans two processes — the `zui` command and the application it
  # spawns — and a third one, the native client, sits between them. Finding out
  # where a slow launch went therefore needs timestamps that can be lined up
  # across all three, so every mark carries wall-clock milliseconds rather than
  # a per-process elapsed time.
  #
  # Nobody wants this on an ordinary run, so it writes nothing unless
  # ZUI_TRACE_STARTUP is set, and it never raises: a trace that breaks the
  # thing it measures is worse than no trace.
  module Trace
    VARIABLE = "ZUI_TRACE_STARTUP"

    class << self
      def enabled?
        return @enabled unless @enabled.nil?

        @enabled = Object.const_defined?(:ENV) && !ENV[VARIABLE].to_s.empty?
      rescue StandardError
        @enabled = false
      end

      def mark(phase, detail = nil)
        return unless enabled?

        line = "zui trace #{now} #{phase}"
        line += " #{detail}" if detail
        $stderr.puts(line)
      rescue StandardError
        nil
      end

      # Returns the elapsed milliseconds, so a caller can both time a phase and
      # report it in one place.
      def measure(phase)
        return yield unless enabled?

        started = now
        result = yield
        mark(phase, "took=#{now - started}ms")
        result
      end

      private

      def now
        if Object.const_defined?(:Process) && Process.respond_to?(:clock_gettime)
          Process.clock_gettime(Process::CLOCK_REALTIME, :millisecond)
        else
          (Time.now.to_f * 1000).round
        end
      end
    end
  end
end
