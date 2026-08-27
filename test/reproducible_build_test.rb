# frozen_string_literal: true

require "minitest/autorun"
require "rubygems/package"
require "stringio"
require "tmpdir"
require "zlib"
require_relative "../lib/zui"

class ReproducibleBuildTest < Minitest::Test
  def test_normalizes_timestamps_and_hashes_tree_contents
    Dir.mktmpdir do |directory|
      FileUtils.mkdir_p(File.join(directory, "nested"))
      File.write(File.join(directory, "nested", "app.rb"), "puts :ready\n")
      File.symlink("nested/app.rb", File.join(directory, "entrypoint"))

      Zui::ReproducibleBuild.normalize_tree(directory)

      paths = Dir.glob(File.join(directory, "**", "*"), File::FNM_DOTMATCH) << directory
      assert paths.all? { |path| File.lstat(path).mtime.to_i == Zui::ReproducibleBuild::DEFAULT_EPOCH }
      assert_match(/\A[0-9a-f]{64}\z/, Zui::ReproducibleBuild.tree_digest(directory))
    end
  end

  def test_removes_hdiutil_random_segment_identifier
    Dir.mktmpdir do |directory|
      first = fake_udif(File.join(directory, "first.dmg"), "first-identifier")
      second = fake_udif(File.join(directory, "second.dmg"), "other-identifier")

      Zui::ReproducibleBuild.normalize_udif_segment_id(first)
      Zui::ReproducibleBuild.normalize_udif_segment_id(second)

      assert_equal File.binread(first), File.binread(second)
      assert_equal "\0" * 16, File.binread(first, 16, 64)
    end
  end

  def test_writes_identical_tar_gzip_archives_with_normalized_metadata
    Dir.mktmpdir do |directory|
      root = File.join(directory, "root")
      FileUtils.mkdir_p(File.join(root, "nested"))
      File.write(File.join(root, "nested", "app.rb"), "puts :ready\n")
      File.symlink("nested/app.rb", File.join(root, "entrypoint"))
      first = File.join(directory, "first.tar.gz")
      second = File.join(directory, "second.tar.gz")
      epoch = 1_234_567_890

      Zui::ReproducibleBuild.tar_gzip(first, root:, entries: Dir.children(root), epoch:, prefix: ".")
      File.utime(Time.now, Time.now, File.join(root, "nested", "app.rb"))
      Zui::ReproducibleBuild.tar_gzip(second, root:, entries: Dir.children(root).reverse, epoch:, prefix: ".")

      assert_equal File.binread(first), File.binread(second)
      assert_equal 255, File.binread(first, 10).getbyte(9)
      gzip = Zlib::GzipReader.open(first)
      assert_equal epoch, gzip.mtime.to_i
      entries = []
      Gem::Package::TarReader.new(StringIO.new(gzip.read)) do |tar|
        tar.each { |entry| entries << [entry.full_name, entry.header.mtime] }
      end
      assert_equal epoch, entries.to_h.fetch("./nested/app.rb")
      assert_includes entries.map(&:first), "./entrypoint"
    ensure
      gzip&.close
    end
  end

  private

  def fake_udif(path, identifier)
    footer = "\0" * Zui::ReproducibleBuild::UDIF_FOOTER_SIZE
    footer[0, 4] = "koly"
    footer[64, 16] = identifier
    File.binwrite(path, footer)
    path
  end
end
