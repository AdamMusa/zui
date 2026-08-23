# Platform support

Zui desktop applications support Linux and macOS. The Ruby API, protocol, renderer, components,
and application source are identical on both platforms; only the compiled Qt host and package
layout differ.

## Linux

The release gem includes an x86-64 Linux host. Other architectures are compiled on first launch.
Building a host requires:

- CMake 3.21 or newer;
- a C++17 compiler;
- Qt 6 Core, Gui, Qml, Quick, and Quick Controls 2 development packages.

Applications using multimedia, WebEngine, Quick 3D, SVG/vector images, shader tools, or other
optional catalog entries must install the corresponding Qt module. Missing optional modules are
reported as component errors; Zui does not silently change component type.

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
CMake and Qt 6, then run `zui bundle`. Zui creates:

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

## Adapter boundary

Platform and desktop-environment adapters depend on Zui, never the other way around. The
`omarchy-ui` gem provides the Omarchy/Quickshell plugin lifecycle, panel/bar surfaces, theme bridge,
validation, installation, and shell restart behavior while using Zui for the DSL and catalog.
