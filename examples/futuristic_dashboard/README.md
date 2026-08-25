# Nebula Command

A futuristic orbital-operations dashboard written entirely in Ruby with the Zui DSL. It
combines reactive state, scheduled telemetry, GPU particles/effects, SVG image assets, charts,
gauges, navigation, controls, and an image-backed result dialog without application-owned QML.

## Run

From this directory with the development checkout:

```bash
../../bin/zui run main.rb
```

Or with the installed gem:

```bash
zui run main.rb
```

Try **Initiate scan**, **Engage overdrive**, the navigation rail, and the neural-copilot switch.

## Distribution

Release metadata and the Linux application icon are declared in `config.rb`. Build native Linux
packages with:

```bash
zui bundle --dist
```

This creates both DEB and RPM artifacts in `dist/`.
