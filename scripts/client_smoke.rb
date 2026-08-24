# frozen_string_literal: true

require "fileutils"
require "rbconfig"
require "tmpdir"

root = File.expand_path("..", __dir__)
archive = File.expand_path(ARGV.fetch(0))
cli = File.expand_path(ARGV.fetch(1))
program = File.expand_path(ARGV.fetch(2))
abort "client archive is missing: #{archive}" unless File.file?(archive)
abort "client checksum is missing: #{archive}.sha256" unless File.file?("#{archive}.sha256")
abort "installed Zui CLI is missing: #{cli}" unless File.file?(cli)
abort "smoke application is missing: #{program}" unless File.file?(program)

windows = RUBY_PLATFORM.match?(/mswin|mingw|cygwin/i)
Dir.mktmpdir("zui-client-smoke-") do |cache|
  environment = {
    "ZUI_CACHE_HOME" => cache,
    "ZUI_CLIENT_ARCHIVE" => archive,
    "ZUI_CLIENT_CHECKSUM" => "#{archive}.sha256"
  }
  abort "zui doctor --fix failed" unless system(
    environment, RbConfig.ruby, cli, "doctor", "--fix", chdir: root
  )
  abort "zui doctor failed after repair" unless system(
    { "ZUI_CACHE_HOME" => cache }, RbConfig.ruby, cli, "doctor", chdir: root
  )

  log_path = File.join(root, "tmp", "runtime-smoke-#{Process.pid}.log")
  FileUtils.mkdir_p(File.dirname(log_path))
  run_environment = {
    "ZUI_CACHE_HOME" => cache,
    "QT_QPA_PLATFORM" => "offscreen",
    "QT_QUICK_BACKEND" => "software"
  }
  status = nil
  File.open(log_path, "wb") do |log|
    spawn_options = { chdir: root }
    spawn_options[windows ? :new_pgroup : :pgroup] = true
    pid = Process.spawn(run_environment, RbConfig.ruby, cli, "run", program,
                        out: log, err: log, **spawn_options)
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
    abort "configured Zui client exited before the smoke deadline (status #{status.exitstatus})"
  end

  FileUtils.rm_f(log_path)
end

puts "Zui doctor repair and client smoke passed."
