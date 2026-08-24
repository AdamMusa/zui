# Zui

Zui builds beautiful native desktop applications in pure Ruby, with first-class UI, state,
events, bindings, animation, media, GPU effects, 3D, and application logic. Applications are
Ruby and assets—there is no application UI language to learn alongside Ruby.

This repository is the reusable core. Distribution integrations live at its edges:

- Linux and Windows desktop applications use the standalone Qt host.
- macOS applications use the same host inside a standard application bundle.
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

Build and install the gem directly from a checkout:

```bash
gem build zui.gemspec
gem install ./zui-0.0.2.gem
```

`zui run` uses the bundled host for supported release targets. If a matching host is not
bundled, Zui builds and caches it from the checked-in C++ source with CMake and Qt 6.8 or newer.

`zui bundle` produces an application directory on Linux and Windows and a standard `.app` bundle
on macOS. Each package includes the application, Zui Ruby runtime, QML renderer, component catalog,
theme, controls, and native host. Ruby and the required Qt runtime libraries must be available on
the destination machine; native installers can add them with the platform's normal deployment
tools.

See [Platform support](docs/platforms.md) for host requirements and bundle layouts.

Zui has no separate validation command. `run` opens the app directly, and
`bundle` packages the project directly. Ruby, DSL, protocol, resource, and QML
errors are reported by the operation that actually encounters them.

## Reusable application UI

Application UI modules are scoped to one builder instead of being mixed into Zui globally:

```ruby
module TelemetryConsole
  module UI
    def dashboard
      card { text "System online" }
    end
  end

  def self.build
    Zui::Application.new(ui: UI) do
      app(:main, title: "Telemetry Console") { dashboard }
    end
  end

  def self.run = build.run
end

TelemetryConsole.run
```

This keeps `main.rb` at one domain-level call and prevents components from one application leaking
into another application's DSL.

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
