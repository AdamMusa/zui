# Platform support

Zui applications use the same Ruby API, protocol, renderer, catalog, and source on Linux, macOS,
Windows, iOS, and Android. A small versioned client supplies the native Qt/QML engine on desktop.
Mobile builds embed that renderer and mruby inside the application instead of starting a child
process.

## Setup

Install Ruby 3.1 or newer and the gem, then configure the matching native client and lite runtime:

```bash
gem install zui
zui doctor --fix
zui doctor
zui run main.rb
```

`zui doctor --fix` downloads `zui-client-<platform>-<architecture>.tar.gz` and
`zui-runtime-lite-<platform>-<architecture>.tar.gz` with their checksums from the matching GitHub
release. (`zui configure` is the equivalent explicit setup command.) Zui checks each checksum,
archive path, manifest, version, platform, and executable before atomic activation. These archives
are not part of the RubyGem. CMake, C++, mruby build tools, Qt SDKs, Homebrew Qt packages, and Linux
Qt development packages are not desktop end-user prerequisites.

The client contains only:

```text
client.json                # version, platform, executable, private environment paths
bin/ or zui-host.app/      # native process/QML host
lib/ and/or Frameworks/    # deployed Qt libraries
plugins/                   # deployed Qt platform/media/image plugins
qml/                       # Qt QML modules required by the catalog
```

The Zui gem and the project supply the Ruby application and framework QML during development.
`zui run` adds private client paths only to the child process environment; it does not modify shell
startup files or globally set Qt plugin variables.

## Release-gated targets

Native CI builds, packages, installs, and launches clients on these target families:

- Linux x86-64;
- macOS Apple Silicon;
- macOS Intel;
- Windows x86-64.

iOS and Android builds are currently a developer preview. iOS is built on macOS with Xcode and
Qt 6.8 for iOS. Android uses the Android SDK, NDK, and Qt 6.8 Android SDK on macOS, Linux, or
Windows. Both use mruby 4.0 and mruby-json. The resulting `.app` or APK does not require Ruby or
Qt to be installed on the target.

An unavailable architecture fails explicitly during configuration. Zui does not silently compile a
host from source or fall back to a system Qt installation. Additional architectures become supported
when a native release runner and client artifact are added.

## Mobile

The mobile host keeps the Qt event loop and Zui renderer native while replacing the desktop child
process with an in-process mruby bridge:

```text
Application.app or application.apk
├── native Qt/Zui executable and libraries
├── embedded Zui QML and fonts
├── embedded application Ruby bytecode and assets
├── embedded mruby runtime
└── platform launcher icon and optional splash artwork
```

From a project containing `main.rb`, `config.rb`, and mobile PNG icons:

```bash
zui mobile --enable
zui mobile --fix
zui build ios
zui build android
```

The enable step creates project-owned, editable platform configuration without replacing files
that already exist:

```text
android/AndroidManifest.xml
android/zui.gradle
android/Zui.cmake
ios/Info.plist.in
ios/Zui.entitlements
ios/Zui.cmake
ios/Zui.xcconfig
```

The Android directory is used as Qt's `QT_ANDROID_PACKAGE_SOURCE_DIR` overlay, so it can also hold
`res/`, `src/`, and Gradle customizations. Preserve the Qt insertion markers in the generated
manifest. The iOS plist is installed as the Xcode bundle plist and the entitlements file is used
during code signing; an optional `ios/LaunchScreen.storyboard` overrides the generated launch
screen. Android dangerous permissions still require a runtime request, while iOS protected access
requires a matching usage-description string in `Info.plist.in`.

These are vendor-neutral Qt extension points. Put Android module-root configuration in `android/`,
provider plugins/dependencies/repositories and required API-level overrides in `android/zui.gradle`,
and native link rules in `android/Zui.cmake`. Standard `res/`, `assets/`, `libs/`, and `src/`
subdirectories are passed through unchanged. A manifest permission may declare its own
`android:maxSdkVersion`; application-wide compile, minimum, target, or maximum SDK settings belong
in the `android { ... }` block in `zui.gradle`.

On iOS, otherwise-unrecognized files at the `ios/` root are bundled directly, so provider files
such as configuration plists have a defined destination. `ios/Resources/` preserves nested bundle
resources, `ios/Sources/` compiles native bridge code, `ios/Zui.cmake` links or embeds SDKs and
frameworks, and `ios/Zui.xcconfig` supplies Xcode build settings. URL schemes and usage descriptions
belong in `Info.plist.in`, while Apple capabilities belong in `Zui.entitlements`.

`zui mobile --fix` records detected dependency paths in the user's Zui mobile configuration and
repairs missing Qt and mruby sources. The build commands create lean pinned mobile mruby runtimes,
precompile the bundled Ruby source to bytecode, and write products below `dist/ios` and
`dist/android`. The mruby VM and Qt renderer share one native process; mobile does not invoke the
desktop `zui run` child-process launcher.

Install and launch on a simulator or emulator with `zui install ios` or `zui install android`.
For a paired physical phone, use `zui install ios --device` or `zui install android --device`.
An explicit CoreDevice UDID or adb serial can be supplied as `--device=ID`. Physical iPhone builds
request automatic Xcode development signing and require an Apple team saved by setting
`ZUI_APPLE_TEAM` when running `zui mobile --fix`. Physical Android devices require USB debugging
and host authorization. Advanced `zui mobile ios` and `zui mobile android` commands accept SDK
paths and lower-level target options directly.

The current mobile path is lite-only: application code must be mruby compatible and cannot require
arbitrary CRuby gems. App Store and Play Store distribution remain application-owner steps.

## Application bundles

`zui bundle` starts from an OS-specific distribution template and inserts four separate payloads:

```text
application source/assets
  + Zui Ruby/QML framework runtime
  + private mruby (`--lite`) or CRuby (`--full`)
  + configured native Qt/QML client
```

The native client carries the Qt libraries, QML modules, media backends, image plugins, GPU support,
and optional 3D support needed by the desktop catalog. Browser-engine payloads are not part of Zui.
Release builds scan a clean copy of the Zui runtime and package only catalog modules plus their linked
Qt dependencies; they never copy the host machine's complete Qt installation.
Application bundling then performs a second, project-specific tree-shaking pass. It analyzes
production Ruby sources, lazily routes component adapters, resolves transitive QML imports, and
retains the native binary dependency closure for the components that application can create. Image
codec and TLS plugins are selected from literal production asset/URL strings. `.zui-bundle.json`
can declare computed component names plus a Qt Controls `style`, dynamic `features`, additional
`qml_modules`, and exact `plugins`. Requested native capabilities are validated against the client
before pruning; `--no-tree-shake` is the explicit fallback for applications whose metaprogramming
cannot be bounded.
Full CRuby bundles apply the same closure rule to the Ruby runtime. Literal requires in production
application files and locked gem runtime files select standard-library Ruby files, native extensions,
and their linked libraries. CRuby's encoding/transcoding catalog remains complete. The locked gem
require paths are added directly to the private runtime, while Bundler, automatic RubyGems activation,
debug symbols, unused standard-library features, and libraries used only by removed extensions are
omitted. A computed standard-library require can be declared as `ruby.stdlib` in
`.zui-bundle.json`; an unbounded computed require or RubyGems runtime API use conservatively keeps the
complete standard library. `--no-tree-shake` disables both the native and CRuby closure passes.
`zui bundle --dist` adds a native installer layer around this bundle. Release identity and artwork
come from the required project-root `config.rb`. Linux emits DEB and RPM packages, macOS emits a
DMG, and Windows emits an Inno Setup executable. Packaging is native to the target operating system,
validates its icon before bundling, creates artifacts transactionally, and refuses to overwrite an
existing release file.
The current templates require no Ruby installation on the destination. `--lite` is the default and
uses the pinned, platform-specific mruby runtime; applications with external gem requirements use
`--full`, which copies private CRuby and only dependencies resolved by `Gemfile.lock`.

### Linux

```text
application-linux-x86_64/
├── app/                    # Ruby application and assets
├── runtime/lib/            # Zui Ruby framework
├── runtime/ruby/           # private mruby or CRuby
├── runtime/qml/            # renderer, theme, controls, catalog
├── runtime/native/         # complete configured Linux client
├── share/applications/     # desktop entry
├── run
└── zui-bundle.json
```

The directory can be wrapped by AppImage, Flatpak, Snap, `.deb`, `.rpm`, or an Arch package without
changing application code.

### macOS

```text
Application.app/
└── Contents/
    ├── Info.plist
    ├── MacOS/run
    └── Resources/
        ├── app/
        ├── runtime/lib/
        ├── runtime/ruby/    # private mruby or CRuby
        ├── runtime/qml/
        ├── runtime/native/  # deployed and patched macOS client bundle
        └── zui-bundle.json
```

Signing and notarization remain the application's release-owner responsibility; no Qt installation
is required on the destination Mac.

### Windows

```text
application-windows-x86_64/
├── app/                    # Ruby application and assets
├── runtime/lib/            # Zui Ruby framework
├── runtime/ruby/           # private mruby or CRuby
├── runtime/qml/            # renderer, theme, controls, catalog
├── runtime/native/         # host, Qt DLLs, QML modules, plugins
├── run.cmd
└── zui-bundle.json
```

The directory can be used as input to MSIX, MSI, WiX, Inno Setup, or another Windows installer.

## Release construction

CMake, a C++17 toolchain, and the Qt SDK are release-infrastructure dependencies only. Native CI
uses Qt's deployment tooling on macOS and Windows and a relocatable Qt layout on Linux. It also
builds exact pinned mruby and mruby-json revisions for each target. CI validates both manifests and
checksums, installs them through `zui doctor --fix`, and launches standalone `--lite` and `--full`
applications before publishing the archives.

## Adapter boundary

Desktop-environment adapters depend on Zui, never the other way around. The `omarchy-ui` gem owns
Omarchy/Quickshell plugin lifecycle, shell surfaces, theme integration, installation, and restart
behavior while reusing Zui's Ruby DSL and component catalog unchanged.
