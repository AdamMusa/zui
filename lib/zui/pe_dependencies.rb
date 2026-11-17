# frozen_string_literal: true

module Zui
  module PEDependencies
    module_function

    def imports(path)
      data = File.binread(path)
      return unless data.start_with?("MZ") && data.bytesize >= 64

      pe_offset = data.byteslice(0x3c, 4)&.unpack1("V")
      return unless pe_offset && data.byteslice(pe_offset, 4) == "PE\0\0"

      section_count = data.byteslice(pe_offset + 6, 2)&.unpack1("v")
      optional_size = data.byteslice(pe_offset + 20, 2)&.unpack1("v")
      return unless section_count && optional_size

      optional = pe_offset + 24
      magic = data.byteslice(optional, 2)&.unpack1("v")
      directory = case magic
                  when 0x10b then optional + 96
                  when 0x20b then optional + 112
                  else return
                  end
      import_rva = data.byteslice(directory + 8, 4)&.unpack1("V")
      return [] unless import_rva&.positive?

      sections = section_count.times.map do |index|
        offset = optional + optional_size + index * 40
        values = [12, 8, 16, 20].map { |field| data.byteslice(offset + field, 4)&.unpack1("V") }
        return if values.any?(&:nil?)

        values
      end
      rva_offset = lambda do |rva|
        section = sections.find do |virtual, size, raw_size, _raw|
          rva >= virtual && rva < virtual + [size, raw_size].max
        end
        section && section[3] + rva - section[0]
      end
      descriptor = rva_offset.call(import_rva)
      return unless descriptor

      dependencies = []
      loop do
        name_rva = data.byteslice(descriptor + 12, 4)&.unpack1("V")
        break unless name_rva&.positive?

        name_offset = rva_offset.call(name_rva)
        return unless name_offset

        name = data.byteslice(name_offset..)&.split("\0", 2)&.first
        dependencies << name if name&.match?(/\.dll\z/i)
        descriptor += 20
      end
      dependencies.uniq
    rescue Errno::ENOENT, NoMethodError, RangeError
      nil
    end
  end
end
