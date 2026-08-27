# frozen_string_literal: true

require "digest"

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

    def tree_paths(root)
      root = File.expand_path(root)
      paths = Dir.glob(File.join(root, "**", "*"), File::FNM_DOTMATCH)
      paths.reject! { |path| %w[. ..].include?(File.basename(path)) }
      paths << root
      paths
    end
    private_class_method :tree_paths
  end
end
