# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
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

  private

  def fake_udif(path, identifier)
    footer = "\0" * Zui::ReproducibleBuild::UDIF_FOOTER_SIZE
    footer[0, 4] = "koly"
    footer[64, 16] = identifier
    File.binwrite(path, footer)
    path
  end
end
