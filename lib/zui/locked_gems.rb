# frozen_string_literal: true

require "bundler"

module Zui
  class LockedGems
    Spec = Struct.new(
      :name, :version, :full_name, :full_gem_path, :extension_dir, :require_paths,
      :platform, :extensions, :files, :ruby, :default,
      keyword_init: true
    ) do
      def default_gem? = default == true
      def to_ruby = ruby
    end

    def initialize(environment: ENV)
      @environment = environment.to_h
    end

    def specs(project)
      previous = @environment["BUNDLE_GEMFILE"]
      project = File.expand_path(project)
      gemfile = File.join(project, "Gemfile")
      lockfile = File.join(project, "Gemfile.lock")
      raise ArgumentError, "Gemfile not found; add project gems before using --full" unless File.file?(gemfile)
      unless File.file?(lockfile)
        raise ArgumentError, "Gemfile.lock not found; run `bundle install` before using --full"
      end

      ENV["BUNDLE_GEMFILE"] = gemfile
      Bundler.reset!
      definition = Bundler::Definition.build(gemfile, lockfile, nil)
      definition.validate_runtime!
      definition.specs.map do |spec|
        Spec.new(
          name: spec.name,
          version: spec.version,
          full_name: spec.full_name,
          full_gem_path: spec.full_gem_path,
          extension_dir: spec.extension_dir,
          require_paths: spec.require_paths,
          platform: spec.platform,
          extensions: spec.extensions,
          files: spec.files,
          ruby: spec.to_ruby,
          default: spec.default_gem?
        )
      end
    rescue Bundler::BundlerError => error
      raise ArgumentError, "project gems are not ready: #{error.message}"
    ensure
      previous.nil? ? ENV.delete("BUNDLE_GEMFILE") : ENV["BUNDLE_GEMFILE"] = previous
      Bundler.reset!
    end
  end
end
