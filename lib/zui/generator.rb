# frozen_string_literal: true

require "fileutils"

module Zui
  class Generator
    DEFAULT_ASSETS = File.expand_path("generator_assets", __dir__)
    RELEASE_ICONS = %w[ruby.png ruby.icns ruby.ico].freeze

    def initialize(path:, name: nil)
      @path = File.expand_path(path)
      @name = display_name(name || File.basename(@path))
    end

    def create
      raise ArgumentError, "destination already exists: #{@path}" if File.exist?(@path)
      created = true
      FileUtils.mkdir_p(File.join(@path, "components"))
      File.write(File.join(@path, "main.rb"), main_program)
      File.write(File.join(@path, "Gemfile"), gemfile)
      File.write(File.join(@path, "components", "welcome.rb"), welcome_component)
      File.write(File.join(@path, "config.rb"), distribution_config)
      assets = File.join(@path, "assets")
      FileUtils.mkdir_p(assets)
      RELEASE_ICONS.each { |name| FileUtils.cp(File.join(DEFAULT_ASSETS, name), assets) }
      File.write(File.join(@path, "README.md"), readme)
      @path
    rescue StandardError
      FileUtils.remove_entry(@path) if created && File.directory?(@path)
      raise
    end

    private

    def main_program
      <<~RUBY
        # frozen_string_literal: true

        require "zui"
        require_relative "components/welcome"

        module #{constant_name}
          def self.build
            Zui::Application.new(ui: WelcomeComponent) do
              app :main, title: "#{@name}", width: 760, height: 520 do
                welcome_card(title: "Welcome to #{@name}", message: "A native cross-platform Zui application.")
              end
            end
          end

          def self.run = build.run
        end

        #{constant_name}.run
      RUBY
    end

    def gemfile
      <<~RUBY
        source "https://rubygems.org"

        gem "zui", "~> #{VERSION}"

        # Add application gems here. They are included by `zui bundle --full`.
      RUBY
    end

    def welcome_component
      <<~RUBY
        # frozen_string_literal: true

        module WelcomeComponent
          def welcome_card(title:, message:)
            card padding: 24, spacing: 12 do
              text title, style: :heading
              text message, wrap: true
            end
          end
        end
      RUBY
    end

    def readme
      <<~MARKDOWN
        # #{@name}

        A native Linux, macOS, and Windows desktop application written in Ruby with Zui.

        ```bash
        zui doctor --fix # once for each Zui version
        zui run main.rb
        zui bundle
        zui bundle --dist
        ```
      MARKDOWN
    end

    def distribution_config
      <<~RUBY
        # frozen_string_literal: true

        Zui::Dist.configure do
          name #{@name.dump}
          identifier #{"dev.zui.#{slug_name}".dump}
          version "0.1.0"
          publisher "Zui Project"
          description #{"A native #{@name} desktop application.".dump}
          license "MIT"
          homepage "https://github.com/AdamMusa/zui"

          icon linux: "assets/ruby.png",
               macos: "assets/ruby.icns",
               windows: "assets/ruby.ico",
               android: "assets/ruby.png",
               ios: "assets/ruby.png"

          categories "Utility", "Development"
        end
      RUBY
    end

    def display_name(value)
      value.to_s.split(/[-_\s]+/).map { |part| part[0].upcase + part[1..].to_s }.join(" ")
    end

    def constant_name
      value = @name.scan(/[a-z0-9]+/i).map { |part| part[0].upcase + part[1..].to_s }.join
      value = "Application#{value}" if value.match?(/\A\d/)
      value.empty? ? "ZuiApplication" : value
    end

    def slug_name
      value = @name.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-|-\z/, "")
      value.match?(/\A\d/) ? "app-#{value}" : value
    end
  end
end
