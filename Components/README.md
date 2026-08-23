# QML component adapters

`Builtins/` contains the framework-owned renderer for each Ruby component. Every built-in
widget has one file—for example, `Builtins/Button.qml`, `Builtins/Icon.qml`, and
`Builtins/Text.qml`. `ControlNode.qml` only selects a renderer and provides shared lifecycle,
event, animation, and recursive-child infrastructure.

Applications can extend the framework without modifying `ControlNode.qml` or `Service.qml`.
Register an adapter before declaring surfaces:

```ruby
register_component :sparkline,
  qml: "Sparkline.qml",
  properties: %i[values color],
  events: %i[click]
```

Then place `Sparkline.qml` in this directory and render it with:

```ruby
component :sparkline, values: [2, 8, 5, 12], color: "#f44"
```

An adapter is a QML `Item` with any of these framework-injected properties it needs:
`bridge`, `surfaceName`, `controlId`, and `node`. Events are sent with
`bridge.sendEvent(surfaceName, controlId, "click", payload)`.

The registry only accepts local adapter basenames and declares every allowed property and
event. QML source is never accepted from the runtime JSON stream as executable text.

## Animation

Reactive patches can carry native QML transitions:

```ruby
bind(chart, :opacity, animation: animation(duration: 240, easing: :out_cubic)) do
  state.visible ? 1.0 : 0.0
end
```

The bridge validates the transition, preserves the previous value, and runs a QML
`PropertyAnimation` against the adapter property. For an animatable custom property, expose
a QML property with the same name as the registered Ruby property. Adapters remain free to
use QML `Behavior`, `Transition`, `SequentialAnimation`, `ParallelAnimation`, states,
shaders, particles, and any other native QML animation internally.
