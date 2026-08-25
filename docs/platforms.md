# Platform support

Zui applications use the same Ruby API, protocol, renderer, catalog, and source on Linux, macOS,
and Windows. A small versioned client supplies the native Qt/QML engine for each operating system.
Application source never goes into that development client.

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
Qt development packages are not end-user prerequisites.

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

An unavailable architecture fails explicitly during configuration. Zui does not silently compile a
host from source or fall back to a system Qt installation. Additional architectures become supported
when a native release runner and client artifact are added.

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
retains the native binary dependency closure for the components that application can create.
Computed component names can be declared in `.zui-bundle.json`; `--no-tree-shake` is the explicit
fallback for applications whose metaprogramming cannot be bounded.
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
