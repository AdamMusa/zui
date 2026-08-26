# frozen_string_literal: true

ndk = File.expand_path(ENV.fetch("ZUI_ANDROID_NDK"))
abi = ENV.fetch("ZUI_ANDROID_ABI", "arm64-v8a")
api = ENV.fetch("ZUI_ANDROID_API", "28")
build_name = ENV.fetch("ZUI_MRUBY_BUILD", "zui-android-arm64-v8a")
prebuilt = Dir[File.join(ndk, "toolchains", "llvm", "prebuilt", "*")].find do |directory|
  File.executable?(File.join(directory, "bin", "clang"))
end
raise "Android NDK LLVM toolchain not found in #{ndk}" unless prebuilt

target = {
  "arm64-v8a" => "aarch64-linux-android",
  "armeabi-v7a" => "armv7a-linux-androideabi",
  "x86_64" => "x86_64-linux-android",
  "x86" => "i686-linux-android"
}.fetch(abi)
bin = File.join(prebuilt, "bin")
flags = ["-target", "#{target}#{api}", "--sysroot", File.join(prebuilt, "sysroot"), "-fPIC", "-Os"]

MRuby::Build.new do |configuration|
  configuration.toolchain
  configuration.gembox "stdlib"
  configuration.bins = ["mrbc"]
end

MRuby::CrossBuild.new(build_name) do |configuration|
  configuration.toolchain :clang
  configuration.cc.command = File.join(bin, "clang")
  configuration.cxx.command = File.join(bin, "clang++")
  configuration.objc.command = File.join(bin, "clang")
  configuration.asm.command = File.join(bin, "clang")
  [configuration.cc, configuration.cxx, configuration.objc, configuration.asm].each do |compiler|
    compiler.flags = flags + ["-D__ANDROID__", "-DANDROID"]
  end
  configuration.archiver.command = File.join(bin, "llvm-ar")
  configuration.linker.command = File.join(bin, "clang")
  configuration.linker.flags = flags
  configuration.bins = []

  %w[stdlib stdlib-ext math].each do |gembox|
    configuration.gembox gembox
  end
  configuration.gem core: "mruby-method"
  configuration.gem ENV.fetch("ZUI_MRUBY_JSON")
end
