# Standalone Zui applications

These applications were extracted from the Omarchy UI showcase catalog to verify that Zui is a
real desktop framework rather than an Omarchy-specific namespace. They contain only Ruby
application code and assets.

- [Nova Pour](nova_pour/) validates images, asynchronous resources, filtering, state, cart
  simulation, bindings, dialogs, and events.
- [Lumen Forge](lumen_forge/) validates compiled shaders, GPU effects, pointer uniforms, sliders,
  charts, timers, and dynamic component trees.

Validate and launch either application:

```bash
bin/zui validate examples/nova_pour
bin/zui launch examples/nova_pour/main.rb

bin/zui validate examples/lumen_forge
bin/zui launch examples/lumen_forge/main.rb
```

On Linux, generate installable application directories with:

```bash
bin/zui bundle examples/nova_pour
bin/zui bundle examples/lumen_forge
```

Generated bundles are placed under each application's `dist/` directory and intentionally ignored
by Git.
