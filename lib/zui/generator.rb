# frozen_string_literal: true

require "fileutils"

module Zui
  class Generator
    def initialize(path:, name: nil)
      @path = File.expand_path(path)
      @name = name || File.basename(@path).split(/[-_]/).map(&:capitalize).join(" ")
    end

    def create
      raise ArgumentError, "destination already exists: #{@path}" if File.exist?(@path)
      created = true
      FileUtils.mkdir_p(File.join(@path, "components"))
      File.write(File.join(@path, "main.rb"), main_program)
      File.write(File.join(@path, "components", "welcome.rb"), welcome_component)
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

        Zui.app do
          app :main, title: "#{@name}", width: 760, height: 520 do
            welcome_card(title: "Welcome to #{@name}", message: "A native cross-platform Zui application.")
          end
        end
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

        Zui::Builder.include(WelcomeComponent)
      RUBY
    end

    def readme
      <<~MARKDOWN
        # #{@name}

        A native Linux and macOS desktop application written in Ruby with Zui.

        ```bash
        zui validate
        zui launch main.rb
        zui bundle
        ```
      MARKDOWN
    end
  end
end
