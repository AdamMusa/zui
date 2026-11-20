# frozen_string_literal: true

require "fileutils"

module Zui
  module MacOSBundleSeal
    module_function

    def seal!(native_root, command: Command)
      application = File.join(File.expand_path(native_root), "zui-host.app")
      return false unless File.directory?(application)
      executable = File.join(application, "Contents", "MacOS", "zui-host")
      return false unless File.file?(executable)

      restore_framework_links!(File.join(application, "Contents", "Frameworks"))
      result = command.run(
        ["codesign", "--force", "--deep", "--sign", "-", "--timestamp=none", application],
        timeout: 240, max_output_bytes: 2_000_000
      )
      unless result.success?
        raise ArgumentError, "could not seal the bundled macOS Qt runtime: #{result.stderr.strip}"
      end
      application
    rescue Errno::ENOENT, CommandTimeout, CommandOutputLimit => error
      raise ArgumentError, "could not seal the bundled macOS Qt runtime: #{error.message}"
    end

    def restore_framework_links!(framework_root)
      return unless File.directory?(framework_root)

      Dir[File.join(framework_root, "*.framework")].sort.each do |framework|
        name = File.basename(framework, ".framework")
        version = framework_version(framework, name)
        # A framework with no binary is not a framework — it is debris, and
        # codesign refuses the whole bundle over it. One is left behind on
        # every macOS client: purging the browser payload deletes
        # QtPositioning's binary and leaves its directory standing. This used
        # to raise instead, which stopped the repair before it reached the
        # frameworks that did need it, so no macOS application could be sealed
        # at all.
        unless version
          FileUtils.remove_entry(framework)
          next
        end
        ensure_link(File.join(framework, "Versions", "Current"), version)
        ensure_link(File.join(framework, name), "Versions/Current/#{name}")
        resources = File.join(framework, "Versions", version, "Resources")
        ensure_link(File.join(framework, "Resources"), "Versions/Current/Resources") if File.directory?(resources)
      end
    end
    private_class_method :restore_framework_links!

    def framework_version(framework, name)
      versions = File.join(framework, "Versions")
      candidates = Dir.children(versions).reject { |entry| entry == "Current" }.sort
      candidates.find { |entry| File.file?(File.join(versions, entry, name)) }
    end
    private_class_method :framework_version

    def ensure_link(path, target)
      if File.symlink?(path)
        unless File.readlink(path) == target
          raise ArgumentError, "unexpected macOS framework link: #{path} -> #{File.readlink(path)}"
        end
        return
      end
      raise ArgumentError, "macOS framework link path is occupied: #{path}" if File.exist?(path)

      File.symlink(target, path)
    end
    private_class_method :ensure_link
  end
end
