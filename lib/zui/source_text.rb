# frozen_string_literal: true

module Zui
  # Reads framework, project and Qt source text.
  #
  # QML, JavaScript, Ruby, `qmldir` and manifest files are UTF-8 by definition, but Ruby tags a file
  # it reads with `Encoding.default_external`, which follows the caller's locale. Under a locale
  # such as `LC_ALL=C` that is US-ASCII, and the first regular expression applied to a line holding
  # a degree sign or a middle dot raises `invalid byte sequence in US-ASCII`. Reading through this
  # module keeps tree shaking, bundling and the test suite independent of the environment.
  module SourceText
    ENCODING = Encoding::UTF_8

    class << self
      def read(path) = File.read(path, encoding: ENCODING)

      def readlines(path, **options) = File.readlines(path, encoding: ENCODING, **options)

      def foreach(path, &block) = File.foreach(path, encoding: ENCODING, &block)

      # Text that may legitimately contain bytes that are not valid UTF-8, such as a QML file an
      # application supplies; invalid sequences are dropped rather than failing the build.
      def lenient(path)
        File.read(path, encoding: ENCODING, invalid: :replace, undef: :replace, replace: "")
      end
    end
  end
end
