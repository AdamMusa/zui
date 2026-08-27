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

  def test_normalizes_hdiutil_udf_identifiers_and_recording_times
    Dir.mktmpdir do |directory|
      first = fake_udf(File.join(directory, "first.iso"), token: "12345678", second: 10)
      second = fake_udf(File.join(directory, "second.iso"), token: "87654321", second: 11)

      Zui::ReproducibleBuild.normalize_udf(first, epoch: 1_700_000_000, volume_id: "fixture")
      Zui::ReproducibleBuild.normalize_udf(second, epoch: 1_700_000_000, volume_id: "fixture")

      assert_equal File.binread(first), File.binread(second)
      image = File.binread(first)
      assert_equal Digest::SHA256.hexdigest("fixture")[0, 8].upcase, image.byteslice(73, 8)
      assert_equal [0x1000, 2023, 11, 14, 22, 13, 20, 0, 0, 0].pack("vvC8"),
                   image.byteslice(376, 12)
      4.times { |index| assert_valid_udf_tag(image.byteslice(index * 2048, 2048)) }
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

  def fake_udf(path, token:, second:)
    timestamp = [0x1000, 2026, 8, 27, 2, 39, second, 0, 0, 0].pack("vvC8")
    blocks = [
      udf_descriptor(1, 0, 496),
      udf_descriptor(9, 1, 118),
      udf_descriptor(256, 2, 496),
      udf_descriptor(261, 3, 408)
    ]
    blocks[0][73, 8] = token
    blocks[0][376, 12] = timestamp
    blocks[1][16, 12] = timestamp
    blocks[2][16, 12] = timestamp
    blocks[3][96, 12] = timestamp
    blocks[3][324, 20] = "\0*UDF Mac VolumeInfo".b
    blocks[3][358, 12] = timestamp
    blocks[3][370, 12] = timestamp
    blocks.each { |block| finalize_udf_tag(block) }
    File.binwrite(path, blocks.join)
    path
  end

  def udf_descriptor(tag, location, crc_length)
    block = "\0".b * 2048
    block[0, 2] = [tag].pack("v")
    block[2, 2] = [2].pack("v")
    block[10, 2] = [crc_length].pack("v")
    block[12, 4] = [location].pack("V")
    block
  end

  def assert_valid_udf_tag(block)
    length = block.byteslice(10, 2).unpack1("v")
    crc = block.byteslice(8, 2).unpack1("v")
    assert_equal crc, udf_crc16(block.byteslice(16, length))
    checksum = block.byteslice(0, 16).bytes.each_with_index.sum { |byte, index|
      index == 4 ? 0 : byte
    } & 0xff
    assert_equal checksum, block.getbyte(4)
  end

  def finalize_udf_tag(block)
    length = block.byteslice(10, 2).unpack1("v")
    block[8, 2] = [udf_crc16(block.byteslice(16, length))].pack("v")
    block.setbyte(4, 0)
    checksum = block.byteslice(0, 16).bytes.sum & 0xff
    block.setbyte(4, checksum)
  end

  def udf_crc16(data)
    data.each_byte.reduce(0) do |crc, byte|
      crc ^= byte << 8
      8.times { crc = (crc & 0x8000).zero? ? (crc << 1) : ((crc << 1) ^ 0x1021) }
      crc & 0xffff
    end
  end
end
