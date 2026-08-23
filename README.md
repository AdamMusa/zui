# Zui

Zui is a platform-neutral Ruby framework for native desktop interfaces powered by Qt and QML.
Ruby owns the application, component tree, state, events, bindings, animation descriptions, and
business logic. QML is the rendering backend, not application code.

This repository is the reusable core. Distribution integrations live at its edges:

- Linux desktop applications use the standalone Qt host.
- macOS applications use the same Qt host inside an app bundle.
- Omarchy plugins and applications use the separate
  [`omarchy-ui`](https://github.com/AdamMusa/omarchy-ui) adapter.

The first extraction commit establishes the portable Ruby API. The standalone renderer, platform
packagers, and examples are added in subsequent isolated commits.

## Core API

```ruby
require "zui"

Zui.app do
  state count: 0

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

## License

MIT
