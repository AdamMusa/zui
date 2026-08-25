# frozen_string_literal: true

require "pathname"

module Zui
  module Dist
    CONFIG_FILE = "config.rb"
    UNSET = Object.new.freeze
    PLATFORM_ICON_EXTENSIONS = {
      linux: %w[.png .svg],
      macos: %w[.icns],
      windows: %w[.ico]
    }.freeze

    class Config
      attr_reader :name, :identifier, :version, :publisher, :description, :license,
                  :homepage, :icons, :categories

      def initialize(name:, identifier:, version:, publisher:, description:, license:,
                     homepage:, icons:, categories:)
        @name = name
        @identifier = identifier
        @version = version
        @publisher = publisher
        @description = description
        @license = license
        @homepage = homepage
        @icons = icons.transform_keys(&:to_sym).transform_values(&:to_s).freeze
        @categories = categories.map(&:to_s).freeze
        freeze
      end

      def validate!(project:, platform:)
        project = File.realpath(project)
        validate_text!("name", name, maximum: 100)
        validate_text!("publisher", publisher, maximum: 200)
        validate_text!("description", description, maximum: 500)
        validate_text!("license", license, maximum: 100)
        if homepage
          validate_text!("homepage", homepage, maximum: 500)
          unless homepage.match?(%r{\Ahttps?://[^\s]+\z})
            raise ArgumentError, "#{CONFIG_FILE} homepage must be an HTTP or HTTPS URL"
          end
        end
        unless identifier.to_s.match?(/\A[a-z][a-z0-9]*(?:\.[a-z][a-z0-9-]*)+\z/)
          raise ArgumentError, "#{CONFIG_FILE} identifier must be a lowercase reverse-DNS name"
        end
        unless version.to_s.match?(/\A\d+\.\d+\.\d+\z/)
          raise ArgumentError, "#{CONFIG_FILE} version must have three numeric parts, such as 1.2.0"
        end
        if categories.empty? || categories.any? { |value| !value.match?(/\A[A-Za-z][A-Za-z0-9-]*\z/) }
          raise ArgumentError, "#{CONFIG_FILE} categories must contain portable desktop category names"
        end

        icon_path(project, platform)
        self
      end

      def package_name
        value = name.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
        raise ArgumentError, "#{CONFIG_FILE} name must contain letters or numbers" if value.empty?

        value.length < 2 ? "zui-#{value}" : value
      end

      def icon_path(project, platform)
        os = platform.os
        relative = icons[os]
        raise ArgumentError, "#{CONFIG_FILE} must declare icon #{os}: \"path\"" if relative.nil? || relative.empty?
        if Pathname.new(relative).absolute? || relative.include?("\0")
          raise ArgumentError, "#{CONFIG_FILE} #{os} icon must be a project-relative path"
        end

        path = File.expand_path(relative, project)
        unless File.file?(path)
          raise ArgumentError, "#{CONFIG_FILE} #{os} icon was not found: #{relative}"
        end
        real_path = File.realpath(path)
        unless real_path.start_with?("#{File.realpath(project)}#{File::SEPARATOR}")
          raise ArgumentError, "#{CONFIG_FILE} #{os} icon must stay inside the project"
        end
        extension = File.extname(real_path).downcase
        allowed = PLATFORM_ICON_EXTENSIONS.fetch(os)
        unless allowed.include?(extension)
          raise ArgumentError, "#{CONFIG_FILE} #{os} icon must use #{allowed.join(' or ')}"
        end
        raise ArgumentError, "#{CONFIG_FILE} icon is too large" if File.size(real_path) > 20 * 1024 * 1024

        validate_icon_signature!(real_path, extension)
        real_path
      end

      private

      def validate_text!(field, value, maximum:)
        unless value.is_a?(String) && !value.strip.empty? && value.bytesize <= maximum &&
               !value.match?(/[\r\n\0]/)
          raise ArgumentError, "#{CONFIG_FILE} #{field} must be a single non-empty line"
        end
      end

      def validate_icon_signature!(path, extension)
        header = File.binread(path, 512)
        valid = case extension
                when ".png" then header.start_with?("\x89PNG\r\n\x1a\n".b)
                when ".svg" then header.match?(/<svg\b/i)
                when ".icns" then header.start_with?("icns")
                when ".ico" then header.start_with?("\x00\x00\x01\x00".b)
                end
        raise ArgumentError, "#{CONFIG_FILE} icon contents do not match #{extension}" unless valid
      end
    end

    class Builder
      def initialize
        @values = { homepage: nil, icons: {}, categories: ["Utility"] }
      end

      %i[name identifier version publisher description license homepage].each do |field|
        define_method(field) do |value = UNSET|
          raise ArgumentError, "#{field} requires a value" if value.equal?(UNSET)

          @values[field] = value.to_s
        end
      end

      def icon(**paths)
        unknown = paths.keys.map(&:to_sym) - PLATFORM_ICON_EXTENSIONS.keys
        raise ArgumentError, "unknown icon platform: #{unknown.first}" unless unknown.empty?

        @values[:icons].merge!(paths.transform_keys(&:to_sym))
      end

      def categories(*values)
        @values[:categories] = values.flatten.map(&:to_s)
      end

      def build
        required = %i[name identifier version publisher description license]
        missing = required.reject { |field| @values.key?(field) }
        unless missing.empty?
          raise ArgumentError, "#{CONFIG_FILE} is missing: #{missing.join(', ')}"
        end

        Config.new(**@values)
      end
    end

    module_function

    def configure(&block)
      raise ArgumentError, "Dist.configure requires a block" unless block

      builder = Builder.new
      block.arity == 1 ? block.call(builder) : builder.instance_eval(&block)
      builder.build
    end

    def load(project:, platform: Platform.current)
      project = File.expand_path(project)
      path = File.join(project, CONFIG_FILE)
      raise ArgumentError, "#{CONFIG_FILE} not found in project root" unless File.file?(path)
      raise ArgumentError, "#{CONFIG_FILE} is too large" if File.size(path) > 131_072

      value = Module.new.module_eval(File.read(path), path, 1)
      unless value.is_a?(Config)
        raise ArgumentError, "#{CONFIG_FILE} must return Zui::Dist.configure do ... end"
      end
      value.validate!(project:, platform: platform.assert_supported!)
    rescue SyntaxError => error
      raise ArgumentError, "invalid #{CONFIG_FILE}: #{error.message.lines.first.to_s.strip}"
    rescue ScriptError => error
      raise ArgumentError, "#{CONFIG_FILE} failed: #{error.class}: #{error.message}"
    rescue ArgumentError
      raise
    rescue StandardError => error
      raise ArgumentError, "#{CONFIG_FILE} failed: #{error.class}: #{error.message}"
    end
  end
end
