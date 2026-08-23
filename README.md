# Zui

Zui is a platform-neutral Ruby framework for native desktop interfaces powered by Qt and QML.
Ruby owns the application, component tree, state, events, bindings, animation descriptions, and
business logic. QML is the rendering backend, not application code.

This repository is the reusable core. Distribution integrations live at its edges:

- Linux desktop applications use the standalone Qt host.
- macOS applications use the same Qt host inside an app bundle.
- Omarchy plugins and applications use the separate
  [`omarchy-ui`](https://github.com/AdamMusa/omarchy-ui) adapter.

Zui ships a standard Qt `ApplicationWindow`, a bidirectional `QProcess` bridge, its own neutral
theme and controls, and the full built-in component catalog. It has no runtime dependency on
Quickshell or an Omarchy installation.

## Core API

```ruby
require "zui"

Zui.app do
  state :count, 0

  app :main, title: "Counter", width: 640, height: 420 do
    column spacing: 16 do
      label { "Count: #{state.count}" }
      button "Increment" do
        state.count += 1
      end
    end
  end
end
```

## Developer workflow

```bash
gem install zui
zui new telemetry-console
cd telemetry-console
zui run main.rb
zui bundle
```

`zui run` uses the bundled host for supported release targets. If a matching host is not
bundled, Zui builds and caches it from the checked-in C++ source with CMake and Qt 6.

`zui bundle` produces a Linux application directory on Linux and a standard `.app` bundle on
macOS. Each package includes the application, Zui Ruby runtime, QML renderer, component catalog,
theme, controls, and the native host. Ruby and the required Qt runtime libraries must be available
on the destination machine; native packages can add them with the distribution's normal dependency
system.

See [Platform support](docs/platforms.md) for host requirements and bundle layouts.

Zui has no separate validation command. `run` opens the app directly, and
`bundle` packages the project directly. Ruby, DSL, protocol, resource, and QML
errors are reported by the operation that actually encounters them.

## Architecture

```text
Ruby application
  → Zui DSL/state/events
  → versioned JSON protocol
  → native Qt host and process transport
  → platform-neutral QML renderer
  → Qt Quick / Controls / Multimedia / optional modules
```

Every declared component renders as that component or reports an explicit component error. Zui
does not silently substitute images, alternate controls, or application-specific fallbacks.

## License

MIT
