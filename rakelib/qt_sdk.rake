# frozen_string_literal: true

require "set"

namespace :qt do
  # `aqt` installs exactly the modules it is handed, and a Qt module whose own CMake package
  # declares a dependency on a module nobody asked for fails at find_package() with nothing in the
  # QML error to say which add-on is missing. This walks the dependency manifests of an installed
  # SDK and reports the packages that are referenced but absent.
  desc "Report Qt packages an installed SDK references but does not provide (ZUI_QT_HOST/IOS/ANDROID)"
  task :sdk do
    root = File.expand_path("..", __dir__)
    $LOAD_PATH.unshift(File.join(root, "lib"))
    require "zui"

    version = Zui::Mobile::Setup::QT_VERSION
    roots = {
      "host" => ENV["ZUI_QT_HOST"] || File.join(root, "tmp", "Qt", version, "macos"),
      "ios" => ENV["ZUI_QT_IOS"] || File.join(root, "tmp", "Qt", version, "ios"),
      "android" => ENV["ZUI_QT_ANDROID"] || File.join(root, "tmp", "Qt", version, "android_arm64_v8a")
    }.select { |_target, path| File.directory?(File.join(path, "lib", "cmake")) }
    abort("no installed Qt #{version} SDK found; set ZUI_QT_HOST, ZUI_QT_IOS or ZUI_QT_ANDROID") if roots.empty?

    # Bundled third-party libraries and language-server internals are linked statically into the
    # module that carries them and never ship as packages of their own.
    internal = /\AQt6(?:Bundled_|LanguageServer)/
    # The add-on that provides a package, where the name does not follow from the package itself.
    providers = { "Qt6ShaderTools" => "qtshadertools" }
    installed = Zui::Mobile::Setup::QT_MODULE_PACKAGES
    unsatisfied = {}

    roots.each do |target, path|
      cmake = File.join(path, "lib", "cmake")
      available = Dir[File.join(cmake, "Qt6*")].map { |entry| File.basename(entry) }.to_set
      Dir[File.join(cmake, "**", "*Dependencies.cmake")].each do |manifest|
        text = File.read(manifest, encoding: "UTF-8", invalid: :replace, undef: :replace, replace: "")
        text.scan(/_target_deps\s+"([^"]*)"/).flatten.join(";").scan(/Qt6\w+/).uniq.each do |package|
          next if available.include?(package) || package.match?(internal)

          ((unsatisfied[target] ||= {})[package] ||= []) << File.basename(manifest).sub("Dependencies.cmake", "")
        end
      end
      puts "#{target}: #{available.size} Qt packages in #{path}"
    end

    if unsatisfied.empty?
      puts "every Qt package dependency resolves"
      next
    end

    puts
    unsatisfied.each do |target, packages|
      packages.each do |package, users|
        add_on = providers[package] || installed.key(package)
        hint = add_on ? "install the #{add_on} add-on" : "no known add-on provides it"
        puts "#{target}: #{package} is missing, required by #{users.uniq.sort.join(', ')} - #{hint}"
      end
    end
    puts
    puts "Run `zui mobile --fix` to reinstall the SDKs with the current module list."
    abort("#{unsatisfied.values.sum(&:size)} unsatisfied Qt package dependencies")
  end
end
