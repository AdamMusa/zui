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
    private_class_method :tree_paths

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
