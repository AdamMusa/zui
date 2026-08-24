# frozen_string_literal: true

require "fileutils"
require "rbconfig"

root = File.expand_path("..", __dir__)
host = File.expand_path(ARGV.fetch(0))
cli = File.expand_path(ARGV.fetch(1))
program = File.expand_path(ARGV.fetch(2))
abort "native host is not executable: #{host}" unless File.executable?(host)
abort "installed Zui CLI is missing: #{cli}" unless File.file?(cli)
abort "smoke application is missing: #{program}" unless File.file?(program)

log_path = File.join(root, "tmp", "runtime-smoke-#{Process.pid}.log")
FileUtils.mkdir_p(File.dirname(log_path))
windows = RUBY_PLATFORM.match?(/mswin|mingw|cygwin/i)
environment = {
  "QT_QPA_PLATFORM" => "offscreen",
  "QT_QUICK_BACKEND" => "software",
  "ZUI_HOST" => host
}
command = [RbConfig.ruby, cli, "run", program]
spawn_options = { chdir: root }
spawn_options[windows ? :new_pgroup : :pgroup] = true

status = nil
File.open(log_path, "wb") do |log|
  pid = Process.spawn(environment, *command, out: log, err: log, **spawn_options)
  deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5.0
  loop do
    waited = Process.waitpid2(pid, Process::WNOHANG)
    if waited
      status = waited.last
      break
    end
    break if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
    sleep 0.1
  end

  unless status
    if windows
      system("taskkill", "/PID", pid.to_s, "/T", "/F", out: File::NULL, err: File::NULL)
    else
      Process.kill("TERM", -pid)
      sleep 0.2
      Process.kill("KILL", -pid) if Process.waitpid(pid, Process::WNOHANG).nil?
    end
    Process.wait(pid)
  end
rescue Errno::ESRCH, Errno::ECHILD
  nil
end

if status
  warn File.read(log_path)
  abort "installed Zui runtime exited before the smoke window deadline (status #{status.exitstatus})"
end

FileUtils.rm_f(log_path)
puts "Installed Zui runtime smoke passed with #{File.basename(host)}."
