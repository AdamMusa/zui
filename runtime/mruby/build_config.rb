# frozen_string_literal: true

MRuby::Build.new("zui") do |configuration|
  configuration.toolchain
  %w[stdlib stdlib-ext stdlib-io math metaprog].each do |gembox|
    configuration.gembox gembox
  end
  configuration.gem core: "mruby-bin-mrbc"
  configuration.gem core: "mruby-bin-mruby"
  configuration.gem ENV.fetch("ZUI_MRUBY_JSON")

  unless RUBY_PLATFORM.match?(/mswin|mingw|cygwin/i)
    configuration.cc.flags << "-Os"
    configuration.linker.flags << "-s"
  end
end
