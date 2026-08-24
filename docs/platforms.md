# Platform support

Zui desktop applications support Linux, macOS, and Windows. The Ruby API, protocol, renderer,
components, and application source are identical on all three platforms; only the compiled Qt host,
cache directory, and package layout differ.

Every push is gated by native GitHub runners for Linux x86-64, macOS Apple Silicon, macOS Intel,
and Windows x86-64. Each runner tests the Ruby framework and showcase simulations, lints the
complete QML catalog, builds the C++ host from source, installs the generated gem, and starts an
installed-gem application through the native Qt host. Other CPU architectures use the same
source-build path but are not claimed as release-gated until a native runner is added.

## Shared requirements

- Ruby 3.1 or newer;
- CMake 3.21 or newer when a precompiled host is unavailable;
- a C++17 compiler compatible with the installed Qt build;
- Qt 6.8 or newer with Core, Gui, Multimedia, Qml, Quick, Quick Controls 2, and Quick Vector Image.

Catalog entries such as WebEngine, Quick 3D, camera/capture, and shader tooling require their
corresponding Qt modules. A missing module produces an explicit component error; Zui never silently
changes the requested component into another type.

## Linux

The release gem includes an x86-64 Linux host. Other architectures are compiled on first launch.
Building a host requires:

- CMake 3.21 or newer;
- a C++17 compiler;
- Qt 6.8 or newer development packages listed under shared requirements.

`zui bundle` creates:

```text
application-linux-architecture/
├── app/                  # Ruby application and assets
├── bin/zui-host          # native Qt host
├── runtime/lib/          # Zui Ruby framework
├── runtime/qml/          # renderer, theme, controls, component catalog
├── share/applications/   # desktop entry
├── run
└── zui-bundle.json
```

The directory is suitable as the input to an AppImage, Flatpak, Snap, `.deb`, `.rpm`, or Arch
package workflow without changing application code.

## macOS

Build the application on macOS so the host matches the machine's architecture and SDK. Install
CMake and Qt 6.8 or newer, then run `zui bundle`. For a Homebrew development environment:

```bash
brew install ruby cmake qt
gem install zui
zui doctor
zui run main.rb
```

Zui caches a locally built host under `~/Library/Caches/zui` when the gem has no matching
precompiled host. `zui bundle` creates:

```text
Application.app/
└── Contents/
    ├── Info.plist
    ├── MacOS/run
    ├── MacOS/zui-host
    └── Resources/
        ├── app/
        ├── runtime/
        └── zui-bundle.json
```

The result can be processed by `macdeployqt`, code signed, notarized, and distributed through the
usual macOS pipeline. Cross-compiling a macOS host from Linux is intentionally rejected; the bundle
must contain a host built against the destination Qt and Apple SDK.

## Windows

Install Ruby 3.1 or newer, CMake, Qt 6.8 or newer, and a matching C++17 toolchain. The normal tested
combination is RubyInstaller, Qt's MSVC 2022 x86-64 build, and Visual Studio 2022 Build Tools. Then:

```powershell
gem install zui
zui doctor
zui run main.rb
zui bundle
```

When necessary, Zui compiles and caches `zui-host.exe` under `%LOCALAPPDATA%\zui`. A Windows bundle
has this layout:

```text
application-windows-architecture/
├── app/                  # Ruby application and assets
├── bin/zui-host.exe      # native Qt host
├── runtime/lib/          # Zui Ruby framework
├── runtime/qml/          # renderer, theme, controls, component catalog
├── run.cmd               # Explorer and Command Prompt entrypoint
├── run.rb                # argv-safe launcher
└── zui-bundle.json
```

The directory is suitable as input to MSIX, MSI, WiX, Inno Setup, or another Windows packaging
workflow. Use Qt's `windeployqt` when producing a self-contained installer.

## Deployment boundary

`zui bundle` assembles the application and Zui runtime; it does not yet embed Ruby or all Qt shared
libraries. Use `linuxdeployqt`/AppImage tooling on Linux, `macdeployqt` plus signing and notarization
on macOS, or `windeployqt` plus an installer on Windows for a redistributable package.

## Adapter boundary

Platform and desktop-environment adapters depend on Zui, never the other way around. The
`omarchy-ui` gem provides the Omarchy/Quickshell plugin lifecycle, panel/bar surfaces, theme bridge,
validation, installation, and shell restart behavior while using Zui for the DSL and catalog.
