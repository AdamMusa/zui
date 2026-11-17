# frozen_string_literal: true

module PEFixture
  module_function

  def binary(*imports)
    data = "\0".b * 1536
    data[0, 2] = "MZ"
    data[0x3c, 4] = [0x80].pack("V")
    data[0x80, 4] = "PE\0\0"
    data[0x84, 20] = [0x8664, 1, 0, 0, 0, 0xf0, 0].pack("vvVVVvv")
    optional = 0x98
    data[optional, 2] = [0x20b].pack("v")
    data[optional + 120, 4] = [0x1000].pack("V")
    section = optional + 0xf0
    data[section + 8, 16] = [0x500, 0x1000, 0x500, 0x200].pack("V4")
    imports.each_with_index do |name, index|
      descriptor = 0x200 + index * 20
      name_rva = 0x1200 + index * 64
      data[descriptor + 12, 4] = [name_rva].pack("V")
      data[0x400 + index * 64, name.bytesize + 1] = "#{name}\0"
    end
    data
  end
end
