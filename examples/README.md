# Standalone Zui applications

Every application in this directory is pure Ruby plus application assets. They
run through Zui's ordinary Qt host on Linux, macOS, and Windows and contain no Omarchy UI,
Quickshell, shell imports, or application-owned QML.

The complete showcase migration is available app-for-app:

- [Restaurant Drinks](restaurant_drinks/) and its refined [Nova Pour](nova_pour/)
  exercise image loading, filtering, cart state, dialogs, bindings, and order simulation.
- [Futuristic Dashboard](futuristic_dashboard/) exercises telemetry, charts,
  particles, GPU effects, navigation, and scheduled state.
- [Tesla Drive Dashboard](tesla_drive_dashboard/) exercises vehicle simulation,
  image stacks, canvas maps, local audio, controls, telemetry, and animation.
- [Shader Studio](shader_studio/) and its refined [Lumen Forge](lumen_forge/)
  exercise compiled shaders, pointer uniforms, GPU effects, charts, and timers.
- [Cardiac Health Monitor](cardiac_health_monitor/) exercises medical imagery,
  ECG visualization, gauges, heatmaps, particles, and interactive state.
- [Orbital Weather Console](orbital_weather_console/) exercises image-backed
  weather scenes, forecasts, gauges, charts, and live simulation.
- [Quantum Market Terminal](quantum_market_terminal/) exercises portfolio state,
  trading simulation, charts, allocation controls, and transactions.
- [Smart Home Energy](smart_home_energy/) exercises room imagery, lighting,
  device state, energy telemetry, and home simulation.
- [Cinematic Music Studio](cinematic_music_studio/) exercises local/remote media,
  playback state, fluid drag interaction, playlists, and audio controls.
- [Avatar Runner](avatar_runner/) is a compact native game demonstrating keyboard
  focus, pointer input, timed physics, collision detection, Canvas drawing, and batched state.

Launch any example directly:

```bash
zui run examples/tesla_drive_dashboard/main.rb
zui run examples/cardiac_health_monitor/main.rb
zui run examples/smart_home_energy/main.rb
zui run examples/avatar_runner/main.rb
```

Package it for the current platform with `zui bundle`:

```bash
zui bundle examples/tesla_drive_dashboard
# or embed private CRuby and the locked project gems
zui bundle --full examples/tesla_drive_dashboard
```

Generated bundles are placed under each application's `dist/` directory and
are intentionally ignored by Git. Every example has a checked-in `Gemfile.lock`, so both the
default standalone mruby mode and full standalone CRuby mode are reproducible.
