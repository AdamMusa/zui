# frozen_string_literal: true

require "digest"
require "fileutils"
require "rubygems/package"
require "tempfile"
require "zlib"

module Zui
  module ReproducibleBuild
    DEFAULT_EPOCH = 946_684_800
    UDIF_FOOTER_SIZE = 512
    UDIF_SEGMENT_ID_OFFSET = 64
    UDIF_SEGMENT_ID_SIZE = 16
    UDF_BLOCK_SIZE = 2048
    UDF_PRIMARY_VOLUME_DESCRIPTOR = 1
    UDF_LOGICAL_VOLUME_INTEGRITY_DESCRIPTOR = 9
    UDF_FILE_SET_DESCRIPTOR = 256
    UDF_FILE_ENTRY = 261
    ZIP_LOCAL_HEADER = 0x04034b50
    ZIP_CENTRAL_HEADER = 0x02014b50
    ZIP_END_OF_CENTRAL_DIRECTORY = 0x06054b50

    module_function

    def epoch(value = nil)
      parsed = Integer(value || DEFAULT_EPOCH)
      raise ArgumentError if parsed.negative?

      parsed
    rescue ArgumentError, TypeError
      raise ArgumentError, "SOURCE_DATE_EPOCH must be a non-negative integer"
    end

    def normalize_tree(root, epoch: DEFAULT_EPOCH)
      root = File.expand_path(root)
      timestamp = Time.at(self.epoch(epoch)).utc
      tree_paths(root).sort_by { |path| -path.count(File::SEPARATOR) }.each do |path|
        if File.symlink?(path)
          File.lutime(timestamp, timestamp, path)
        else
          File.utime(timestamp, timestamp, path)
        end
      end
      root
    end

    def tree_digest(root, exclude: [])
      root = File.expand_path(root)
      excluded = exclude.map { |path| File.expand_path(path) }
      digest = Digest::SHA256.new
      tree_paths(root).sort.each do |path|
        next if path == root || excluded.include?(File.expand_path(path))

        relative = path.delete_prefix("#{root}#{File::SEPARATOR}").tr(File::SEPARATOR, "/")
        stat = File.lstat(path)
        type = stat.symlink? ? "link" : stat.directory? ? "directory" : "file"
        digest << type << "\0" << relative << "\0" << format("%04o", stat.mode & 0o777) << "\0"
        digest << File.readlink(path) if stat.symlink?
        digest << Digest::SHA256.file(path).digest if stat.file?
        digest << "\0"
      end
      digest.hexdigest
    end

    def normalize_zip(path, epoch: DEFAULT_EPOCH)
      path = File.expand_path(path)
      contents = File.binread(path)
      entries = read_zip_entries(contents)
      dos_time, dos_date = zip_timestamp(epoch)
      local_records = +"".b
      central_records = +"".b

      entries.sort_by { |entry| entry.fetch(:name) }.each do |entry|
        offset = local_records.bytesize
        flags = entry.fetch(:flags) & ~0x0008
        name = entry.fetch(:name)
        local_records << [
          ZIP_LOCAL_HEADER, entry.fetch(:version_needed), flags, entry.fetch(:method), dos_time, dos_date,
          entry.fetch(:crc), entry.fetch(:compressed_size), entry.fetch(:uncompressed_size), name.bytesize, 0
        ].pack("VvvvvvVVVvv")
        local_records << name << entry.fetch(:compressed_data)
        central_records << [
          ZIP_CENTRAL_HEADER, entry.fetch(:version_made), entry.fetch(:version_needed), flags,
          entry.fetch(:method), dos_time, dos_date, entry.fetch(:crc), entry.fetch(:compressed_size),
          entry.fetch(:uncompressed_size), name.bytesize, 0, 0, 0, entry.fetch(:internal_attributes),
          entry.fetch(:external_attributes), offset
        ].pack("VvvvvvvVVVvvvvvVV")
        central_records << name
      end

      central_offset = local_records.bytesize
      count = entries.length
      output = local_records << central_records
      output << [
        ZIP_END_OF_CENTRAL_DIRECTORY, 0, 0, count, count, central_records.bytesize, central_offset, 0
      ].pack("VvvvvVVv")
      temporary = "#{path}.zui-normalize-#{Process.pid}"
      File.binwrite(temporary, output)
      File.chmod(0o644, temporary)
      File.rename(temporary, path)
      path
    ensure
      FileUtils.rm_f(temporary) if defined?(temporary)
    end

    def normalize_udif_segment_id(path)
      size = File.size(path)
      footer = size - UDIF_FOOTER_SIZE
      if footer.negative? || File.binread(path, 4, footer) != "koly"
        raise ArgumentError, "hdiutil did not produce a UDIF disk image: #{path}"
      end

      File.open(path, "r+b") do |file|
        file.seek(footer + UDIF_SEGMENT_ID_OFFSET)
        file.write("\0" * UDIF_SEGMENT_ID_SIZE)
      end
      path
    end

    def normalize_udf(path, epoch: DEFAULT_EPOCH, volume_id: "zui")
      timestamp = udf_timestamp(epoch)
      volume_token = Digest::SHA256.hexdigest(volume_id.to_s)[0, 8].upcase
      File.open(path, "r+b") do |file|
        blocks = file.size / UDF_BLOCK_SIZE
        blocks.times do |index|
          file.seek(index * UDF_BLOCK_SIZE)
          block = file.read(UDF_BLOCK_SIZE)
          next unless block&.bytesize == UDF_BLOCK_SIZE
          next unless valid_udf_descriptor_tag?(block)

          changed = normalize_udf_descriptor(block, timestamp, volume_token)
          next unless changed

          update_udf_descriptor_tag(block)
          file.seek(index * UDF_BLOCK_SIZE)
          file.write(block)
        end
      end
      path
    end

    def tar_gzip(output, root:, entries:, epoch: DEFAULT_EPOCH, prefix: "", include_symlinks: true)
      output = File.expand_path(output)
      root = File.expand_path(root)
      timestamp = self.epoch(epoch)
      raise ArgumentError, "archive root not found: #{root}" unless File.directory?(root)

      FileUtils.mkdir_p(File.dirname(output))
      Tempfile.create([".zui-archive-", ".tar"], File.dirname(output)) do |temporary|
        Array(entries).map(&:to_s).uniq.sort.each do |entry|
          path = File.expand_path(entry, root)
          present = File.exist?(path) || File.symlink?(path)
          unless path != root && path.start_with?("#{root}#{File::SEPARATOR}") && present
            raise ArgumentError, "unsafe archive entry: #{entry.inspect}"
          end
          add_tar_entry(temporary, root, path, timestamp, prefix.to_s, include_symlinks)
        end
        temporary.write("\0" * 1024)
        temporary.flush
        temporary.rewind

        File.open(output, "wb", 0o644) do |archive|
          gzip = Zlib::GzipWriter.new(archive, Zlib::BEST_COMPRESSION)
          gzip.mtime = [timestamp, 0xffff_ffff].min
          IO.copy_stream(temporary, gzip)
          gzip.finish
        end
      end
      # RFC 1952's OS byte does not affect extraction. Pin it to "unknown" so
      # identical inputs stay identical across Unix and Windows build hosts.
      File.open(output, "r+b") do |archive|
        archive.seek(9)
        archive.write("\xff".b)
      end
      output
    end

    def tree_paths(root)
      root = File.expand_path(root)
      paths = Dir.glob(File.join(root, "**", "*"), File::FNM_DOTMATCH)
      paths.reject! { |path| %w[. ..].include?(File.basename(path)) }
      paths << root
      paths
    end

    def read_zip_entries(contents)
      end_offset = contents.rindex([ZIP_END_OF_CENTRAL_DIRECTORY].pack("V"))
      raise ArgumentError, "invalid ZIP archive: end of central directory not found" unless end_offset

      end_record = contents.byteslice(end_offset, 22)
      raise ArgumentError, "invalid ZIP archive: truncated end of central directory" unless end_record&.bytesize == 22

      signature, disk, central_disk, disk_entries, entries, central_size, central_offset, comment_size =
        end_record.unpack("VvvvvVVv")
      unless signature == ZIP_END_OF_CENTRAL_DIRECTORY && disk.zero? && central_disk.zero? &&
             disk_entries == entries && comment_size == contents.bytesize - end_offset - 22
        raise ArgumentError, "unsupported multi-disk or malformed ZIP archive"
      end
      if entries == 0xffff || central_size == 0xffff_ffff || central_offset == 0xffff_ffff
        raise ArgumentError, "ZIP64 archives are not supported for deterministic mobile packaging"
      end
      unless central_offset + central_size == end_offset
        raise ArgumentError, "invalid ZIP archive: central directory boundary mismatch"
      end

      cursor = central_offset
      Array.new(entries) do
        header = contents.byteslice(cursor, 46)
        raise ArgumentError, "invalid ZIP archive: truncated central directory" unless header&.bytesize == 46

        values = header.unpack("VvvvvvvVVVvvvvvVV")
        raise ArgumentError, "invalid ZIP archive: central directory signature mismatch" unless values.fetch(0) == ZIP_CENTRAL_HEADER

        version_made, version_needed, flags, method = values.values_at(1, 2, 3, 4)
        crc, compressed_size, uncompressed_size = values.values_at(7, 8, 9)
        name_size, extra_size, entry_comment_size = values.values_at(10, 11, 12)
        disk_start, internal_attributes, external_attributes, local_offset = values.values_at(13, 14, 15, 16)
        if disk_start != 0 || compressed_size == 0xffff_ffff || uncompressed_size == 0xffff_ffff ||
           local_offset == 0xffff_ffff
          raise ArgumentError, "ZIP64 and multi-disk entries are not supported for deterministic mobile packaging"
        end
        raise ArgumentError, "encrypted ZIP entries are not supported for mobile packaging" unless (flags & 0x0001).zero?

        name = contents.byteslice(cursor + 46, name_size)
        raise ArgumentError, "invalid ZIP archive: truncated entry name" unless name&.bytesize == name_size
        local = contents.byteslice(local_offset, 30)
        raise ArgumentError, "invalid ZIP archive: truncated local header" unless local&.bytesize == 30

        local_values = local.unpack("VvvvvvVVVvv")
        unless local_values.fetch(0) == ZIP_LOCAL_HEADER && local_values.fetch(3) == method
          raise ArgumentError, "invalid ZIP archive: local header mismatch for #{name.inspect}"
        end
        local_name_size, local_extra_size = local_values.values_at(9, 10)
        local_name = contents.byteslice(local_offset + 30, local_name_size)
        raise ArgumentError, "invalid ZIP archive: local entry name mismatch" unless local_name == name

        data_offset = local_offset + 30 + local_name_size + local_extra_size
        compressed_data = contents.byteslice(data_offset, compressed_size)
        unless compressed_data&.bytesize == compressed_size
          raise ArgumentError, "invalid ZIP archive: truncated entry data for #{name.inspect}"
        end
        cursor += 46 + name_size + extra_size + entry_comment_size
        {
          name:, version_made:, version_needed:, flags:, method:, crc:, compressed_size:,
          uncompressed_size:, internal_attributes:, external_attributes:, compressed_data:
        }
      end.tap do
        raise ArgumentError, "invalid ZIP archive: central directory size mismatch" unless cursor == end_offset
      end
    end

    def zip_timestamp(value)
      time = Time.at(epoch(value)).utc
      year = [[time.year, 1980].max, 2107].min
      dos_time = (time.hour << 11) | (time.min << 5) | (time.sec / 2)
      dos_date = ((year - 1980) << 9) | (time.month << 5) | time.day
      [dos_time, dos_date]
    end
    private_class_method :tree_paths

    def normalize_udf_descriptor(block, timestamp, volume_token)
      case block.unpack1("v")
      when UDF_PRIMARY_VOLUME_DESCRIPTOR
        block[73, 8] = volume_token
        block[376, 12] = timestamp
      when UDF_LOGICAL_VOLUME_INTEGRITY_DESCRIPTOR, UDF_FILE_SET_DESCRIPTOR
        block[16, 12] = timestamp
      when UDF_FILE_ENTRY
        block[96, 12] = timestamp
        marker = block.index("\0*UDF Mac VolumeInfo".b)
        if marker
          block[marker + 34, 12] = timestamp
          block[marker + 46, 12] = timestamp
        end
      else
        return false
      end
      true
    end
    private_class_method :normalize_udf_descriptor

    def valid_udf_descriptor_tag?(block)
      return false unless [2, 3].include?(block.byteslice(2, 2).unpack1("v"))

      length = block.byteslice(10, 2).unpack1("v")
      return false if length > UDF_BLOCK_SIZE - 16
      return false unless udf_crc16(block.byteslice(16, length)) == block.byteslice(8, 2).unpack1("v")

      checksum = block.byteslice(0, 16).bytes.each_with_index.sum do |byte, index|
        index == 4 ? 0 : byte
      end & 0xff
      checksum == block.getbyte(4)
    end
    private_class_method :valid_udf_descriptor_tag?

    def update_udf_descriptor_tag(block)
      length = block.byteslice(10, 2).unpack1("v")
      raise ArgumentError, "invalid UDF descriptor CRC length: #{length}" if length > UDF_BLOCK_SIZE - 16

      block[8, 2] = [udf_crc16(block.byteslice(16, length))].pack("v")
      block.setbyte(4, 0)
      checksum = block.byteslice(0, 16).bytes.sum & 0xff
      block.setbyte(4, checksum)
    end
    private_class_method :update_udf_descriptor_tag

    def udf_crc16(data)
      data.each_byte.reduce(0) do |crc, byte|
        crc ^= byte << 8
        8.times { crc = (crc & 0x8000).zero? ? (crc << 1) : ((crc << 1) ^ 0x1021) }
        crc & 0xffff
      end
    end
    private_class_method :udf_crc16

    def udf_timestamp(epoch)
      time = Time.at(self.epoch(epoch)).utc
      [0x1000, time.year].pack("vv") +
        [time.month, time.day, time.hour, time.min, time.sec, 0, 0, 0].pack("C8")
    end
    private_class_method :udf_timestamp

    def add_tar_entry(archive, root, path, timestamp, prefix, include_symlinks)
      relative = path.delete_prefix("#{root}#{File::SEPARATOR}").tr(File::SEPARATOR, "/")
      archive_path = [prefix.delete_suffix("/"), relative].reject(&:empty?).join("/")
      name, header_prefix = split_tar_name(archive_path)
      stat = File.lstat(path)
      attributes = {
        name:, prefix: header_prefix, mode: stat.mode & 0o777, mtime: timestamp,
        uid: 0, gid: 0, uname: "root", gname: "root"
      }
      if stat.directory?
        archive.write(Gem::Package::TarHeader.new(**attributes, size: 0, typeflag: "5").to_s)
        Dir.children(path).sort.each do |child|
          add_tar_entry(archive, root, File.join(path, child), timestamp, prefix, include_symlinks)
        end
      elsif stat.symlink?
        return unless include_symlinks

        archive.write(
          Gem::Package::TarHeader.new(
            **attributes, size: 0, typeflag: "2", linkname: File.readlink(path)
          ).to_s
        )
      elsif stat.file?
        archive.write(Gem::Package::TarHeader.new(**attributes, size: stat.size).to_s)
        File.open(path, "rb") { |source| IO.copy_stream(source, archive) }
        padding = (512 - (stat.size % 512)) % 512
        archive.write("\0" * padding)
      else
        raise ArgumentError, "unsupported archive entry: #{path}"
      end
    end
    private_class_method :add_tar_entry

    def split_tar_name(path)
      if path.bytesize > 256
        raise Gem::Package::TooLongFileName, "archive path is longer than 256 bytes: #{path}"
      end
      return [path, ""] if path.bytesize <= 100

      parts = path.split("/", -1)
      name = parts.pop
      prefix = parts.join("/")
      while !parts.empty? && (prefix.bytesize > 155 || name.empty?)
        name = "#{parts.pop}/#{name}"
        prefix = parts.join("/")
      end
      if name.bytesize > 100 || prefix.empty? || prefix.bytesize > 155
        raise Gem::Package::TooLongFileName, "archive path cannot fit a USTAR header: #{path}"
      end
      [name, prefix]
    end
    private_class_method :split_tar_name
  end
end
