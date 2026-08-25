<p align="center">
  <img src="docs/assets/readme-hero.svg" width="100%" alt="Zui — native desktop applications in pure Ruby">
</p>

<h1 align="center">Native desktop applications in pure Ruby</h1>

<p align="center">
  Build reactive Linux, macOS, and Windows interfaces with one Ruby API, a native Qt renderer,
  and no application-owned QML or browser runtime.
</p>

<p align="center">
  <a href="https://rubygems.org/gems/zui"><img alt="RubyGem" src="https://img.shields.io/gem/v/zui?style=flat-square&color=9cff57&labelColor=111711"></a>
  <a href="https://github.com/AdamMusa/zui/actions/workflows/platforms.yml"><img alt="Native platforms" src="https://github.com/AdamMusa/zui/actions/workflows/platforms.yml/badge.svg"></a>
  <img alt="Ruby 3.1 or newer" src="https://img.shields.io/badge/Ruby-%E2%89%A5%203.1-cc342d?style=flat-square&labelColor=111711">
  <img alt="241 components" src="https://img.shields.io/badge/components-241-46e8ff?style=flat-square&labelColor=111711">
  <a href="LICENSE"><img alt="MIT license" src="https://img.shields.io/badge/license-MIT-a79cff?style=flat-square&labelColor=111711"></a>
</p>

<p align="center">
  <a href="#quick-start">Start</a> ·
  <a href="#platform-support">Platforms</a> ·
  <a href="#component-catalog">Components</a> ·
  <a href="#reactive-by-design">Reactivity</a> ·
  <a href="#how-zui-runs">Architecture</a> ·
  <a href="#ship-an-application">Distribution</a> ·
  <a href="#showcase-applications">Examples</a> ·
  <a href="https://zui.alkimist.dev">Documentation</a>
</p>

---

Zui is a desktop UI framework for Ruby. Application code owns the interface, state, behavior,
and assets; Zui owns the rendering protocol, native host, platform-neutral QML implementation,
and complete component catalog. The result is a normal desktop application—not a web page inside
a window.

<table>
  <tr>
    <td width="33%"><strong>One application language</strong><br>Compose UI, state, bindings, events, commands, timers, and application logic in Ruby.</td>
    <td width="33%"><strong>Native desktop renderer</strong><br>Render through Qt Quick, Controls, Multimedia, GPU effects, Shapes, and optional 3D modules.</td>
    <td width="33%"><strong>Private verified runtime</strong><br>Install a checksummed native client without changing system Qt or shell configuration.</td>
  </tr>
  <tr>
    <td><strong>241 named components</strong><br>Use specific controls with validated properties and events instead of a generic markup escape hatch.</td>
    <td><strong>Reactive by default</strong><br>Update only changed properties and publish multi-value transactions as atomic patch batches.</td>
    <td><strong>Portable source</strong><br>Run the same application on Linux, macOS, Windows, or through an environment adapter such as Omarchy UI.</td>
  </tr>
</table>

<p align="center">
  <img src="examples/nova_pour/preview.png" width="880" alt="Nova Pour, a complete pure-Ruby Zui desktop application">
</p>

<p align="center"><sub>Nova Pour is one of the complete applications included in the showcase catalog.</sub></p>

## Quick start

Install Ruby 3.1 or newer and the gem. Zui downloads its version-matched native client only when
you explicitly configure it:

```bash
gem install zui
zui doctor --fix
zui new telemetry-console
cd telemetry-console
zui run main.rb
```

That is the complete development setup. You do not need a Qt SDK, CMake, a C++ compiler, or a
system-wide Qt installation.

`zui doctor --fix` downloads the native client for the installed Zui version, verifies its
SHA-256 checksum and manifest, and activates it atomically in the user cache. It does not modify
shell startup files or global Qt environment variables.

## Your first application

```ruby
require "zui"

module Counter
  def self.run
    Zui.app do
      state :count, 0

      app :main, title: "Counter", width: 640, height: 420 do
        container padding: 24 do
          column spacing: 16 do
            label "Counter"
            text { "Count: #{state.count}" }
            button "Increment" do
              state.count += 1
            end
          end
        end
      end
    end
  end
end

Counter.run
```

The source is ordinary Ruby. Zui validates the declared tree, sends it through a versioned JSON
protocol, and renders it with native Qt components. Application QML is neither required nor
accepted through the runtime protocol.

## Reactive by design

State, bindings, animation, scheduled work, and events live in the same builder context:

```ruby
Zui.app do
  state :status, "online"
  state :uptime, 0

  app :main, title: "Service Monitor", width: 720, height: 480 do
    card padding: 24 do
      column spacing: 12 do
        indicator = badge state.status
        bind(indicator, :value) { state.status.upcase }
        bind(indicator, :foreground) { state.status == "online" ? "#9cff57" : "#ff6f7d" }

        text { "Uptime: #{state.uptime}s" }

        button "Reconnect" do
          transaction do
            state.status = "online"
            state.uptime = 0
          end
        end
      end
    end
  end

  every(1) { state.uptime += 1 }
end
```

- `state` defines application-owned values.
- Value components can take a block for their primary reactive property.
- `bind` connects any declared property to application state.
- `transaction` publishes related changes together.
- `after`, `every`, and `async` schedule application work.
- `animate` and animation components use native render-side transitions.
- `dynamic` rebuilds data-dependent child structures without rebuilding the whole application.

Reusable UI modules are scoped to one application builder, so domain components do not leak into
other applications:

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
end
```

## Platform support

Zui uses the same Ruby API, protocol, renderer, catalog, and application source on every supported
desktop target. Each release is gated by CI that builds, packages, installs, and launches the
matching native client.

| Operating system | Architecture | Native client | `zui bundle` output | Release status |
| --- | --- | --- | --- | --- |
| Linux | x86-64 | `zui-client-linux-x86_64` | Portable application directory | Supported and CI verified |
| macOS | Apple Silicon | `zui-client-macos-arm64` | Standard `.app` bundle | Supported and CI verified |
| macOS | Intel x86-64 | `zui-client-macos-x86_64` | Standard `.app` bundle | Supported and CI verified |
| Windows | x86-64 | `zui-client-windows-x86_64` | Portable application directory | Supported and CI verified |

The application bundle expects Ruby 3.1 or newer on the destination. Installers that carry a
private Ruby can point `ZUI_RUBY` at that executable.

Unsupported architectures fail explicitly during configuration. Zui never silently compiles Qt,
uses a system Qt installation, or downloads an asset for a different platform. See the complete
[platform and bundle layouts](docs/platforms.md).

## Component catalog

Zui 0.0.6 registers **241 built-in components**. Every entry has a named Ruby builder method,
property and event schema, native QML renderer, reactive patch support, and contract tests.

| Category | Count | Representative components |
| --- | ---: | --- |
| Foundation and layout | 28 | `container`, `grid_layout`, `scroll`, `split_view`, `application_window` |
| Display, content, and media | 24 | `text`, `image`, `markdown`, `video`, `model_view_3d` |
| Buttons and input | 36 | `button`, `text_field`, `slider`, `date_picker`, `multi_select` |
| Navigation and structure | 20 | `tabs`, `drawer`, `stack_view`, `breadcrumb`, `key_catcher` |
| Menus, dialogs, and feedback | 19 | `dialog`, `popup`, `toast`, `progress_ring`, `bottom_sheet` |
| Data and collections | 22 | `list_view`, `grid_view`, `table_view`, `tree_view`, `calendar` |
| Charts and visualization | 16 | `line_chart`, `candlestick_chart`, `heatmap`, `gauge`, `legend` |
| Drawing and interaction | 16 | `canvas`, `shape`, `shader_effect`, `drag_area`, `particle_system` |
| Animation, state, and timing | 32 | `animation`, `transition`, `timer`, `state_group`, `spring_animation` |
| Effects | 7 | `multi_effect`, `blur`, `drop_shadow`, `colorize`, `glow` |
| Multimedia and capture | 12 | `media_player`, `camera`, `audio_input`, `video_output`, `screen_capture` |
| Models and utilities | 9 | `list_model`, `settings`, `clipboard`, `standard_paths` |

Zui does not silently replace unavailable components with screenshots, generic controls, or
application-specific fallbacks. A declared component either renders as that component or reports
an explicit error.

- Browse the [complete source-backed component reference](https://zui.alkimist.dev/components).
- Review the [component coverage matrix](docs/component-coverage.md).

## Command-line workflow

| Command | Purpose |
| --- | --- |
| `zui new NAME` | Generate a pure-Ruby application with a reusable UI module and tests |
| `zui doctor` | Report Ruby, platform, native-client, run, and bundle readiness without changing anything |
| `zui doctor --fix` | Download, verify, and install the missing versioned native client |
| `zui configure` | Perform the same explicit native-client installation directly |
| `zui run FILE` | Launch a Ruby entry point through the private native client |
| `zui bundle [DIRECTORY]` | Assemble the application, Zui framework, and native runtime for the current OS |
| `zui bundle --name NAME --output PATH` | Override the generated product name and destination |
| `zui version` | Print the installed framework version |

Zui has no separate validation command. Ruby, DSL, schema, resource, protocol, and renderer errors
are reported by the operation that encounters them.

## How Zui runs

```text
┌─────────────────────────────────────────────────────────────────────┐
│ Ruby application                                                   │
│ UI modules · state · bindings · events · commands · assets         │
└──────────────────────────────┬──────────────────────────────────────┘
                               │ versioned JSON protocol
┌──────────────────────────────▼──────────────────────────────────────┐
│ Zui native client                                                  │
│ process transport · schema validation · lifecycle · error boundary │
└──────────────────────────────┬──────────────────────────────────────┘
                               │ declared component tree + patches
┌──────────────────────────────▼──────────────────────────────────────┐
│ Platform-neutral renderer                                          │
│ ControlNode · theme · controls · 241-component QML catalog         │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
              Qt Quick · Controls · Multimedia · GPU · 3D
```

The Ruby process owns application logic. The native client owns the Qt event loop and graphics
runtime. The renderer applies validated trees and bounded reactive patch batches across the
process boundary.

The client intentionally excludes browser-engine payloads. Zui is desktop-only and does not use
HTML, CSS, JavaScript, WebView, Electron, or Qt WebEngine to render application interfaces.

## Native client integrity

The RubyGem contains the Ruby framework and QML catalog, but not a platform client. Native clients
are built by the release matrix and attached to the matching GitHub tag.

During setup, Zui verifies:

1. The release asset name matches the detected platform and architecture.
2. The downloaded archive matches its published SHA-256 checksum.
3. Every archive path is safe before extraction.
4. `client.json` has the expected format, Zui version, platform, executable, and bundle capability.
5. Activation completes atomically in the versioned user cache.

The private client includes the host executable, linked Qt libraries, QML modules, plugins, and
translations required by the catalog. `zui run` exposes those paths only to its child process.

## Ship an application

```bash
zui bundle
# or
zui bundle path/to/application --name "Telemetry Console"
```

Every distribution combines three deliberately separate payloads:

```text
application Ruby source and assets
  + Zui Ruby/QML framework runtime
  + configured native Qt/QML client
```

| Platform | Generated shape | Suitable next step |
| --- | --- | --- |
| Linux | Self-contained directory with `run` and desktop entry | AppImage, Flatpak, Snap, `.deb`, `.rpm`, or Arch package |
| macOS | Standard `.app` directory | Sign, notarize, and distribute with the application's release identity |
| Windows | Self-contained directory with `run.cmd` | MSIX, MSI, WiX, Inno Setup, or another installer |

No system Qt installation is used by the finished bundle. Signing, notarization, installer format,
store submission, and application identity remain the release owner's responsibility.

## Showcase applications

The repository includes complete Ruby applications rather than isolated visual snippets:

| Application | What it demonstrates |
| --- | --- |
| [Avatar Runner](examples/avatar_runner/) | Keyboard focus, pointer input, timed physics, Canvas drawing, and atomic state patches |
| [Nova Pour](examples/nova_pour/) | Image loading, filtering, cart state, dialogs, bindings, and order simulation |
| [Tesla Drive Dashboard](examples/tesla_drive_dashboard/) | Vehicle simulation, image stacks, Canvas maps, local audio, telemetry, and animation |
| [Lumen Forge](examples/lumen_forge/) | Compiled shaders, pointer uniforms, GPU effects, charts, and timers |
| [Cardiac Health Monitor](examples/cardiac_health_monitor/) | Medical imagery, ECG visualization, gauges, heatmaps, particles, and live state |
| [Orbital Weather Console](examples/orbital_weather_console/) | Image-backed weather scenes, forecasts, gauges, charts, and simulation |
| [Quantum Market Terminal](examples/quantum_market_terminal/) | Portfolio state, trading simulation, charts, allocation controls, and transactions |
| [Smart Home Energy](examples/smart_home_energy/) | Room imagery, lighting, device state, energy telemetry, and home simulation |
| [Cinematic Music Studio](examples/cinematic_music_studio/) | Local and remote media, playback state, seeking, playlists, and audio controls |

Run any showcase through the normal client:

```bash
zui run examples/avatar_runner/main.rb
zui run examples/tesla_drive_dashboard/main.rb
zui bundle examples/nova_pour
```

See the [complete showcase index](examples/).

## Omarchy integration

Zui is platform-neutral and has no runtime dependency on Quickshell or Omarchy. The separate
[`omarchy-ui`](https://github.com/AdamMusa/omarchy-ui) adapter adds shell applications, bar widgets,
panels, plugin lifecycle, theme integration, and Omarchy packaging while reusing the same Ruby DSL,
protocol, and component catalog.

The dependency direction remains one-way: desktop-environment adapters depend on Zui; Zui never
contains environment-specific branches.

## Develop Zui itself

Clone the repository and run the complete local suite:

```bash
git clone https://github.com/AdamMusa/zui.git
cd zui
scripts/test
```

The suite covers the Ruby API, state engine, protocol, CLI, distributions, examples, QML contracts,
QML linting when available, the C++ host build, and an offscreen runtime smoke test.

Build and install the gem directly:

```bash
gem build zui.gemspec
gem install ./zui-0.0.6.gem
```

Release CI additionally constructs and audits a relocatable native client, installs the built gem,
repairs a fresh client cache, and launches a real application on every supported target.

## Troubleshooting

| Symptom | Resolution |
| --- | --- |
| `Client: not configured` | Run `zui doctor --fix` once for the installed Zui version |
| Platform or architecture is unsupported | Use one of the release-gated targets above or add a verified native-client runner and artifact |
| A bundle cannot find Ruby | Install Ruby 3.1+ or point `ZUI_RUBY` at an application-private Ruby executable |
| A component reports a resource or module error | Check the declared asset path and run `zui doctor`; Zui will not substitute another component |
| Audio, camera, or capture is unavailable | Confirm OS permissions, devices, codecs, and platform media services |
| The native client looks stale after a framework update | Run `zui doctor --fix`; client caches are isolated by Zui version |

## Documentation and support

| Resource | Purpose |
| --- | --- |
| [Official documentation](https://zui.alkimist.dev) | Guides, concepts, and searchable API documentation |
| [Component reference](https://zui.alkimist.dev/components) | Properties, events, container behavior, and validated Ruby examples for all 241 components |
| [Platform support](docs/platforms.md) | Native-client setup, target matrix, and OS-specific bundle layouts |
| [Component coverage](docs/component-coverage.md) | Complete built-in catalog checklist |
| [GitHub Releases](https://github.com/AdamMusa/zui/releases) | Versioned native clients and SHA-256 checksums |
| [RubyGems](https://rubygems.org/gems/zui) | Published framework versions |
| [Issue tracker](https://github.com/AdamMusa/zui/issues) | Focused bug reports and feature proposals |

## License

Zui is available under the [MIT License](LICENSE). Bundled third-party fonts and runtime
dependencies retain their respective licenses; see [third-party notices](THIRD_PARTY_NOTICES.md).

<p align="center">
  <strong>Build the interface in Ruby. Let Zui carry it to the desktop.</strong>
</p>
