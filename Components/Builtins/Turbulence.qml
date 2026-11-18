import QtQuick
import QtQuick.Particles

// QtQuick.Particles/Turbulence. Pushes particles around with a noise field.
//
// Qt allocates that noise field at the affector's own size, so one affector
// covering a large surface costs a large grid. The particle_system wrapper
// already mitigates that by tiling; this component keeps the same guard and
// exposes its limit as `grid_size`, with 0 meaning a single untiled field.
Item {
  id: turbulenceRoot
  property var renderer: null

  readonly property var particleSystem: nativeHandle(renderer ? renderer.prop("system", "") : "", "nativeParticleSystem")
  readonly property var affectedArea: nativeHandle(renderer ? renderer.prop("shape", "") : "", "nativeExtruder")

  readonly property real fieldWidth: Math.max(0, Number(renderer ? renderer.prop("width", 0) : 0))
  readonly property real fieldHeight: Math.max(0, Number(renderer ? renderer.prop("height", 0) : 0))
  readonly property real gridLimit: Number(renderer ? renderer.prop("grid_size", 256) : 256)
  readonly property real effectiveGridLimit: gridLimit > 0 ? Math.max(32, gridLimit) : Math.max(fieldWidth, fieldHeight)
  readonly property int columns: Math.max(1, Math.ceil(fieldWidth / effectiveGridLimit))
  readonly property int rows: Math.max(1, Math.ceil(fieldHeight / effectiveGridLimit))
  readonly property real tileWidth: fieldWidth / columns
  readonly property real tileHeight: fieldHeight / rows

  function nativeHandle(controlId, handle) {
    var name = String(controlId || "")
    if (!renderer || name === "") return null
    var host = renderer.findRenderedItem(name)
    if (!host) return null
    var value = host[handle]
    return value === undefined ? null : value
  }

  function stringList(value) {
    if (Array.isArray(value)) {
      var names = []
      for (var index = 0; index < value.length; index++) names.push(String(value[index]))
      return names
    }
    var single = String(value === undefined || value === null ? "" : value)
    return single === "" ? [] : [single]
  }

  function send(name, payload) {
    if (renderer && renderer.subscribed(name)) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }

  // Qt hands every affector a real extruder covering its whole area, so an
  // unset or unresolved shape falls back to the same thing rather than null.
  RectangleShape { id: uniformArea; fill: true }

  Repeater {
    model: turbulenceRoot.columns * turbulenceRoot.rows

    delegate: Turbulence {
      id: nativeTurbulence
      required property int index
      readonly property int column: index % turbulenceRoot.columns
      readonly property int row: Math.floor(index / turbulenceRoot.columns)

      system: turbulenceRoot.particleSystem
      groups: turbulenceRoot.stringList(turbulenceRoot.renderer ? turbulenceRoot.renderer.prop("groups", []) : [])
      whenCollidingWith: turbulenceRoot.stringList(turbulenceRoot.renderer ? turbulenceRoot.renderer.prop("when_colliding_with", []) : [])
      enabled: turbulenceRoot.renderer ? turbulenceRoot.renderer.prop("enabled", true) !== false : true
      once: turbulenceRoot.renderer ? turbulenceRoot.renderer.prop("once", false) === true : false
      shape: turbulenceRoot.affectedArea ? turbulenceRoot.affectedArea : uniformArea
      strength: Number(turbulenceRoot.renderer ? turbulenceRoot.renderer.prop("strength", 10) : 10)
      noiseSource: turbulenceRoot.renderer ? turbulenceRoot.renderer.assetUrl(turbulenceRoot.renderer.prop("noise_source", "")) : ""
      x: Number(turbulenceRoot.renderer ? turbulenceRoot.renderer.prop("x", 0) : 0) + column * turbulenceRoot.tileWidth
      y: Number(turbulenceRoot.renderer ? turbulenceRoot.renderer.prop("y", 0) : 0) + row * turbulenceRoot.tileHeight
      width: turbulenceRoot.tileWidth
      height: turbulenceRoot.tileHeight

      onAffected: function (x, y) { turbulenceRoot.send("affected", { x: x, y: y }) }
      onEnabledChanged: turbulenceRoot.send("enabled_change", { value: nativeTurbulence.enabled })
    }
  }
}
