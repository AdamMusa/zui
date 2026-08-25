# frozen_string_literal: true

require "fileutils"
require "json"
require "rbconfig"
require "tmpdir"
require_relative "../lib/zui"

client_archive = File.expand_path(ARGV.fetch(0) do
  abort "Usage: runtime_modes_smoke.rb CLIENT.tar.gz LITE.tar.gz ZUI_CLI PROGRAM"
end)
lite_archive = File.expand_path(ARGV.fetch(1) do
  abort "Usage: runtime_modes_smoke.rb CLIENT.tar.gz LITE.tar.gz ZUI_CLI PROGRAM"
end)
cli = File.expand_path(ARGV.fetch(2) do
  abort "Usage: runtime_modes_smoke.rb CLIENT.tar.gz LITE.tar.gz ZUI_CLI PROGRAM"
end)
program = File.expand_path(ARGV.fetch(3) do
  abort "Usage: runtime_modes_smoke.rb CLIENT.tar.gz LITE.tar.gz ZUI_CLI PROGRAM"
end)
[client_archive, lite_archive].each do |archive|
  abort "archive is missing: #{archive}" unless File.file?(archive)
  abort "archive checksum is missing: #{archive}.sha256" unless File.file?("#{archive}.sha256")
end
abort "installed Zui CLI is missing: #{cli}" unless File.file?(cli)
abort "smoke application is missing: #{program}" unless File.file?(program)

windows = RUBY_PLATFORM.match?(/mswin|mingw|cygwin/i)
macos = RUBY_PLATFORM.match?(/darwin/i)

def terminate(pid, windows)
  if windows
    system("taskkill", "/PID", pid.to_s, "/T", "/F", out: File::NULL, err: File::NULL)
  else
    Process.kill("TERM", -pid)
    sleep 0.2
    Process.kill("KILL", -pid) if Process.waitpid(pid, Process::WNOHANG).nil?
  end
rescue Errno::ESRCH, Errno::ECHILD
  nil
end

def launch_for_smoke(path, log_path, windows:, macos:)
  command = windows ? ["cmd.exe", "/d", "/c", path] : [path]
  environment = {
    "ZUI_RUBY" => nil,
    "QT_QPA_PLATFORM" => macos ? nil : "offscreen",
    "QT_QUICK_BACKEND" => "software",
    "QML_IMPORT_PATH" => nil,
    "QML2_IMPORT_PATH" => nil,
    "QT_PLUGIN_PATH" => nil,
    "QT_QPA_PLATFORM_PLUGIN_PATH" => nil,
    "DYLD_FRAMEWORK_PATH" => nil,
    "DYLD_LIBRARY_PATH" => nil,
    "RUBYLIB" => nil,
    "GEM_HOME" => nil,
    "GEM_PATH" => nil
  }
  status = nil
  File.open(log_path, "wb") do |log|
    options = { out: log, err: log }
    options[windows ? :new_pgroup : :pgroup] = true
    pid = Process.spawn(environment, *command, **options)
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
    terminate(pid, windows) unless status
    Process.wait(pid) unless status
  rescue Errno::ECHILD
    nil
  end

  log = File.read(log_path)
  fatal = [
    /Zui runtime crashed/i,
    /QQmlApplicationEngine failed/i,
    /LoadError|NoMethodError|NameError|SyntaxError/,
    /cannot load library|library not loaded:/i,
    /module ".+" (?:plugin ".+" not found|is not installed)/i
  ].find { |pattern| log.match?(pattern) }
  warn log if status || fatal
  abort "bundled application exited before the smoke deadline" if status
  abort "bundled application reported a fatal runtime error: #{fatal.inspect}" if fatal
end

Dir.mktmpdir("zui-runtime-modes-") do |directory|
  project = File.join(directory, "project")
  cache = File.join(directory, "cache")
  FileUtils.mkdir_p(project)
  FileUtils.cp(program, File.join(project, "main.rb"))
  File.write(File.join(project, "Gemfile"), <<~RUBY)
    source "https://rubygems.org"
    gem "zui", path: #{Zui::FRAMEWORK_ROOT.dump}
  RUBY
  lock_environment = { "BUNDLE_GEMFILE" => File.join(project, "Gemfile") }
  abort "could not lock the smoke project Gemfile" unless system(
    lock_environment, RbConfig.ruby, "-S", "bundle", "lock", "--local", chdir: project
  )

  configuration = {
    "ZUI_CACHE_HOME" => cache,
    "ZUI_CLIENT_ARCHIVE" => client_archive,
    "ZUI_CLIENT_CHECKSUM" => "#{client_archive}.sha256",
    "ZUI_LITE_RUNTIME_ARCHIVE" => lite_archive,
    "ZUI_LITE_RUNTIME_CHECKSUM" => "#{lite_archive}.sha256"
  }
  abort "zui doctor --fix failed" unless system(
    configuration, RbConfig.ruby, cli, "doctor", "--fix", chdir: project
  )

  %w[lite full].each do |mode|
    suffix = macos ? ".app" : ""
    destination = File.join(directory, "#{mode}#{suffix}")
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    abort "zui bundle --#{mode} failed" unless system(
      { "ZUI_CACHE_HOME" => cache }, RbConfig.ruby, cli, "bundle", "--#{mode}",
      "--output", destination, project
    )
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
    runtime_root = macos ? File.join(destination, "Contents", "Resources", "runtime", "ruby") :
                           File.join(destination, "runtime", "ruby")
    descriptor = JSON.parse(File.read(File.join(runtime_root, "runtime.json")))
    expected_engine = mode == "lite" ? "mruby" : "cruby"
    abort "#{mode} bundle embedded #{descriptor['engine'].inspect}" unless descriptor["engine"] == expected_engine
    launcher = macos ? File.join(destination, "Contents", "MacOS", "run") :
                       File.join(destination, windows ? "run.cmd" : "run")
    launch_for_smoke(
      launcher, File.join(directory, "#{mode}.log"), windows:, macos:
    )
    size = Dir[File.join(destination, "**", "*")].sum { |path| File.file?(path) ? File.size(path) : 0 }
    puts format("Runtime smoke: %s %.2fs %.1f MB", mode, elapsed, size / 1_048_576.0)
  end
end

puts "Zui lite and full standalone runtime smoke passed."
