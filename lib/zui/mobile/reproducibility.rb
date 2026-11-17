# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "tmpdir"

module Zui
  module Mobile
    BuildIdentity = Struct.new(
      :platform, :artifact_kind, :artifact_sha256, :payload_sha256, :signed,
      :source_date_epoch, :toolchain,
      keyword_init: true
    ) do
      def to_h
        {
          "platform" => platform,
          "artifact_kind" => artifact_kind,
          "artifact_sha256" => artifact_sha256,
          "payload_sha256" => payload_sha256,
          "signed" => signed,
          "source_date_epoch" => source_date_epoch,
          "toolchain" => toolchain
        }
      end
    end

    ReproducibilityReport = Struct.new(
      :verified, :payload_byte_identical, :artifact_byte_identical, :first, :second,
      keyword_init: true
    ) do
      def to_h
        {
          "verified" => verified,
          "payload_byte_identical" => payload_byte_identical,
          "artifact_byte_identical" => artifact_byte_identical,
          "first" => first.to_h,
          "second" => second.to_h
        }
      end
    end

    module Reproducibility
      MACH_O_MAGICS = %w[
        feedface feedfacf cefaedfe cffaedfe cafebabe bebafeca cafebabf bfbafeca
      ].map { |hex| [hex].pack("H*") }.freeze

      module_function

      def ios_identity(app:, signed:, source_date_epoch:, toolchain:, command: Command)
        signed = signed == true
        ReproducibleBuild.normalize_tree(app, epoch: source_date_epoch)
        artifact_sha256 = ReproducibleBuild.tree_digest(app)
        payload_sha256 = signed ? unsigned_ios_payload_digest(app, source_date_epoch, command) : artifact_sha256
        BuildIdentity.new(
          platform: "ios", artifact_kind: "directory-tree", artifact_sha256:, payload_sha256:,
          signed:, source_date_epoch:, toolchain: canonical_toolchain(toolchain)
        )
      end

      def android_identity(apk:, unsigned_sha256:, source_date_epoch:, toolchain:)
        BuildIdentity.new(
          platform: "android", artifact_kind: "file", artifact_sha256: Digest::SHA256.file(apk).hexdigest,
          payload_sha256: unsigned_sha256, signed: true, source_date_epoch:,
          toolchain: canonical_toolchain(toolchain)
        )
      end

      def verify!(first, second)
        unless first.platform == second.platform && first.toolchain == second.toolchain &&
               first.source_date_epoch == second.source_date_epoch
          raise ArgumentError, "mobile reproducibility verification used different build inputs or toolchains"
        end

        payload_identical = first.payload_sha256 == second.payload_sha256
        artifact_identical = first.artifact_sha256 == second.artifact_sha256
        unless payload_identical
          raise ArgumentError,
                "mobile #{first.platform} payload is not reproducible: " \
                "#{first.payload_sha256} != #{second.payload_sha256}"
        end
        if require_identical_signed_artifact?(first) && !artifact_identical
          raise ArgumentError,
                "mobile #{first.platform} artifact is not byte-reproducible: " \
                "#{first.artifact_sha256} != #{second.artifact_sha256}"
        end

        ReproducibilityReport.new(
          verified: true, payload_byte_identical: true, artifact_byte_identical: artifact_identical,
          first:, second:
        )
      end

      def write_metadata(result)
        identity = result.identity
        return unless identity

        artifact = result.app || result.apk
        path = "#{artifact}.zui-build.json"
        contents = { "format" => 1, "identity" => identity.to_h }
        contents["reproducibility"] = result.reproducibility.to_h if result.reproducibility
        File.write(path, "#{JSON.pretty_generate(contents)}\n")
        timestamp = Time.at(identity.source_date_epoch).utc
        File.utime(timestamp, timestamp, path)
        result.metadata = path
      end

      def unsigned_ios_payload_digest(app, source_date_epoch, command)
        Dir.mktmpdir("zui-ios-payload-") do |directory|
          copy = File.join(directory, File.basename(app))
          FileUtils.cp_r(app, copy, preserve: true)
          strip_ios_signatures(copy, command)
          ReproducibleBuild.normalize_tree(copy, epoch: source_date_epoch)
          ReproducibleBuild.tree_digest(copy)
        end
      end

      def strip_ios_signatures(app, command)
        mach_o_files(app).each do |path|
          result = command.run(["codesign", "--remove-signature", path], timeout: 120,
                               max_output_bytes: 8_000_000)
          next if result.success?

          details = [result.stdout, result.stderr].join("\n").strip
          raise ArgumentError, "could not normalize iOS code signature for #{path}: #{details}"
        end
        Dir.glob(File.join(app, "**", "_CodeSignature"), File::FNM_DOTMATCH).sort.reverse_each do |path|
          FileUtils.rm_rf(path)
        end
        Dir.glob(File.join(app, "**", "CodeResources"), File::FNM_DOTMATCH).sort.each do |path|
          FileUtils.rm_f(path)
        end
        FileUtils.rm_f(File.join(app, "embedded.mobileprovision"))
      end

      def mach_o_files(root)
        seen = {}
        Dir.glob(File.join(root, "**", "*"), File::FNM_DOTMATCH).select do |path|
          next false unless File.file?(path) && !File.symlink?(path)

          real = File.realpath(path)
          next false if seen[real]

          seen[real] = true
          File.size(path) >= 4 && MACH_O_MAGICS.include?(File.binread(path, 4))
        end.sort
      end

      def require_identical_signed_artifact?(identity)
        identity.platform != "ios" || !identity.signed
      end

      def canonical_toolchain(toolchain)
        toolchain.transform_keys(&:to_s).sort.to_h.freeze
      end
    end
  end
end
