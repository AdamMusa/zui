# Zui

Zui builds beautiful native desktop applications in pure Ruby, with first-class UI, state,
events, bindings, animation, media, GPU effects, 3D, and application logic. Applications are
Ruby and assets—there is no application UI language to learn alongside Ruby.

Zui is desktop-only. Its native client intentionally excludes browser-engine payloads while
retaining the complete desktop component catalog.

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
      text { "Count: #{state.count}" }
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
zui doctor --fix
zui new telemetry-console
cd telemetry-console
zui run main.rb
zui bundle
```

Build and install the gem directly from a checkout:

```bash
gem build zui.gemspec
gem install ./zui-0.0.3.gem
```

`zui doctor --fix` is the one-time setup for each Zui version and platform. It downloads the
matching versioned client from GitHub Releases, verifies its SHA-256 checksum and manifest, and
installs it in the native user cache. `zui configure` performs the same explicit setup operation.
The prebuilt client is never packaged in or downloaded from the RubyGem. It contains the native
host and its Qt/QML engine libraries—not the developer's application, Ruby source, or the Zui
Ruby/QML framework. Setup never changes the global shell environment; `zui run` supplies the
client paths only to the child application.

Developers install Ruby and the `zui` gem. They do not install CMake, a C++ compiler, or Qt. Those
tools are used only by Zui's release CI to produce the platform clients.

`zui bundle` uses a platform template to produce an application directory on Linux and Windows or
a standard `.app` on macOS. The package combines the application's Ruby/assets, the Zui framework
runtime and catalog, and a private copy of the configured native Qt/QML client. No system Qt
installation is used by the finished bundle. The current bundle format expects Ruby 3.1 or newer
on the destination and supports `ZUI_RUBY` when an installer provides a private Ruby executable.

See [Platform support](docs/platforms.md) for host requirements and bundle layouts.

`zui doctor` is read-only: it reports platform, Ruby, client, run, and bundle readiness. Add
`--fix` to download and install the missing client from GitHub Releases. Zui has no separate
validation command; Ruby, DSL, protocol, resource, and QML errors are reported by the operation
that encounters them.

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
