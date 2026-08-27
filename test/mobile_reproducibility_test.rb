# frozen_string_literal: true

require "json"
require "minitest/autorun"
require "tmpdir"
require_relative "../lib/zui"

class MobileReproducibilityTest < Minitest::Test
  def test_unsigned_ios_identity_normalizes_bundle_timestamps
    Dir.mktmpdir do |directory|
      first = create_app(File.join(directory, "First.app"), changed: Time.at(1_800_000_000))
      second = create_app(File.join(directory, "Second.app"), changed: Time.at(1_900_000_000))

      identities = [first, second].map do |app|
        Zui::Mobile::Reproducibility.ios_identity(
          app:, signed: false, source_date_epoch: 1_700_000_000,
          toolchain: { qt: "6.8.3", architecture: "arm64" }
        )
      end

      assert_equal identities.first.payload_sha256, identities.last.payload_sha256
      assert_equal identities.first.artifact_sha256, identities.last.artifact_sha256
      report = Zui::Mobile::Reproducibility.verify!(*identities)
      assert report.verified
      assert report.artifact_byte_identical
    end
  end

  def test_signed_ios_verification_compares_the_signature_normalized_payload
    first = identity(platform: "ios", artifact: "signature-one", payload: "payload", signed: true)
    second = identity(platform: "ios", artifact: "signature-two", payload: "payload", signed: true)

    report = Zui::Mobile::Reproducibility.verify!(first, second)

    assert report.verified
    assert report.payload_byte_identical
    refute report.artifact_byte_identical
  end

  def test_android_verification_requires_the_signed_apk_to_be_byte_identical
    first = identity(platform: "android", artifact: "apk-one", payload: "payload", signed: true)
    second = identity(platform: "android", artifact: "apk-two", payload: "payload", signed: true)

    error = assert_raises(ArgumentError) { Zui::Mobile::Reproducibility.verify!(first, second) }

    assert_includes error.message, "artifact is not byte-reproducible"
  end

  def test_writes_machine_readable_build_identity_next_to_the_artifact
    Dir.mktmpdir do |directory|
      apk = File.join(directory, "application.apk")
      File.write(apk, "signed package")
      build_identity = identity(platform: "android", artifact: "artifact", payload: "payload", signed: true)
      result = Zui::Mobile::Result.new(apk:, identity: build_identity)

      Zui::Mobile::Reproducibility.write_metadata(result)

      metadata = JSON.parse(File.read(result.metadata))
      assert_equal "payload", metadata.dig("identity", "payload_sha256")
      assert_equal build_identity.source_date_epoch, File.mtime(result.metadata).to_i
    end
  end

  private

  def create_app(path, changed:)
    FileUtils.mkdir_p(File.join(path, "Resources"))
    File.write(File.join(path, "Runner"), "native executable")
    File.write(File.join(path, "Resources", "main.qml"), "Item {}\n")
    paths = Dir.glob(File.join(path, "**", "*"), File::FNM_DOTMATCH) << path
    paths.each { |entry| File.utime(changed, changed, entry) }
    path
  end

  def identity(platform:, artifact:, payload:, signed:)
    Zui::Mobile::BuildIdentity.new(
      platform:, artifact_kind: "fixture", artifact_sha256: artifact, payload_sha256: payload,
      signed:, source_date_epoch: 1_700_000_000, toolchain: { "qt" => "6.8.3" }
    )
  end
end
