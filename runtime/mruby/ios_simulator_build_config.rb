# frozen_string_literal: true

sdk = ENV.fetch("ZUI_IOS_SDK") { ENV.fetch("ZUI_IOS_SIMULATOR_SDK") }
architecture = ENV.fetch("ZUI_IOS_ARCH") { ENV.fetch("ZUI_IOS_SIMULATOR_ARCH", "arm64") }
deployment_target = ENV.fetch("ZUI_IOS_DEPLOYMENT_TARGET", "16.0")
build_name = ENV.fetch("ZUI_MRUBY_BUILD", "zui-ios-simulator")
platform = ENV.fetch("ZUI_IOS_PLATFORM", "simulator")
target = "#{architecture}-apple-ios#{deployment_target}#{platform == 'simulator' ? '-simulator' : ''}"

MRuby::CrossBuild.new(build_name) do |configuration|
  configuration.toolchain :clang

  [configuration.cc, configuration.cxx, configuration.objc].each do |compiler|
    compiler.flags += ["-target", target, "-isysroot", sdk, "-fPIC", "-Os"]
  end
  configuration.linker.flags += ["-target", target, "-isysroot", sdk]
  configuration.bins = []

  %w[stdlib stdlib-ext math].each do |gembox|
    configuration.gembox gembox
  end
  configuration.gem core: "mruby-method"
  configuration.gem ENV.fetch("ZUI_MRUBY_JSON")
end
