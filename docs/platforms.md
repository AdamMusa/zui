# Platform support

Zui applications use the same Ruby API, protocol, renderer, catalog, and source on Linux, macOS,
and Windows. A small versioned client supplies the native Qt/QML engine for each operating system.
Application source never goes into that development client.

## Setup

Install Ruby 3.1 or newer and the gem, then configure the matching native client:

```bash
gem install zui
zui doctor --fix
zui doctor
zui run main.rb
```

`zui doctor --fix` downloads `zui-client-<platform>-<architecture>.tar.gz` and its checksum from the
matching GitHub release. (`zui configure` is the equivalent explicit setup command.) Zui checks
the checksum, archive paths, manifest format, framework version, platform, executable, and bundle
capability before atomically activating it. The native archive is not part of the RubyGem. CMake,
C++, Qt SDKs, Homebrew Qt packages, and Linux Qt development packages are not end-user
prerequisites.

The client contains only:

```text
client.json                # version, platform, executable, private environment paths
bin/ or zui-host.app/      # native process/QML host
lib/ and/or Frameworks/    # deployed Qt libraries
plugins/                   # deployed Qt platform/media/image plugins
qml/                       # Qt QML modules required by the catalog
resources/                 # native resources such as Qt WebEngine data when required
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

`zui bundle` starts from an OS-specific distribution template and inserts three separate payloads:

```text
application source/assets
  + Zui Ruby/QML framework runtime
  + configured native Qt/QML client
```

The native client is copied as a whole so Qt libraries, QML modules, media backends, image plugins,
GPU support, optional 3D, and WebEngine support do not disappear between development and packaging.
The current templates expect Ruby 3.1 or newer on the destination; an installer can point
`ZUI_RUBY` at a private Ruby executable.

### Linux

```text
application-linux-x86_64/
├── app/                    # Ruby application and assets
├── runtime/lib/            # Zui Ruby framework
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
├── runtime/qml/            # renderer, theme, controls, catalog
├── runtime/native/         # host, Qt DLLs, QML modules, plugins
├── run.cmd
├── run.rb
└── zui-bundle.json
```

The directory can be used as input to MSIX, MSI, WiX, Inno Setup, or another Windows installer.

## Release construction

CMake, a C++17 toolchain, and the Qt SDK are release-infrastructure dependencies only. Native CI
uses Qt's deployment tooling on macOS and Windows and a relocatable Qt layout on Linux, writes a
strict `client.json`, packages a tar archive, verifies installation through `zui doctor --fix`, and
launches a real offscreen Zui application before publishing an asset.

## Adapter boundary

Desktop-environment adapters depend on Zui, never the other way around. The `omarchy-ui` gem owns
Omarchy/Quickshell plugin lifecycle, shell surfaces, theme integration, installation, and restart
behavior while reusing Zui's Ruby DSL and component catalog unchanged.
