# frozen_string_literal: true

MRuby::Build.new("zui") do |configuration|
  configuration.toolchain
  configuration.gembox "default"
  configuration.gem ENV.fetch("ZUI_MRUBY_JSON")

  unless RUBY_PLATFORM.match?(/mswin|mingw|cygwin/i)
    configuration.cc.flags << "-Os"
    configuration.linker.flags << "-s"
  end
end
