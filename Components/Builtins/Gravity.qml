import QtQuick
import QtQuick.Particles

// QtQuick.Particles/Gravity. Accelerates particles in a fixed direction.
//
// Qt also carries an `acceleration` property that is an alias of `magnitude`;
// exposing both would give two Ruby properties one native value, so only
// `magnitude` is exposed.
Item {
  id: gravityRoot
  property var renderer: null

  readonly property var particleSystem: nativeHandle(renderer ? renderer.prop("system", "") : "", "nativeParticleSystem")
  readonly property var affectedArea: nativeHandle(renderer ? renderer.prop("shape", "") : "", "nativeExtruder")

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

  Gravity {
    id: nativeGravity
    system: gravityRoot.particleSystem
    groups: gravityRoot.stringList(gravityRoot.renderer ? gravityRoot.renderer.prop("groups", []) : [])
    whenCollidingWith: gravityRoot.stringList(gravityRoot.renderer ? gravityRoot.renderer.prop("when_colliding_with", []) : [])
    enabled: gravityRoot.renderer ? gravityRoot.renderer.prop("enabled", true) !== false : true
    once: gravityRoot.renderer ? gravityRoot.renderer.prop("once", false) === true : false
    shape: gravityRoot.affectedArea ? gravityRoot.affectedArea : uniformArea
    x: Number(gravityRoot.renderer ? gravityRoot.renderer.prop("x", 0) : 0)
    y: Number(gravityRoot.renderer ? gravityRoot.renderer.prop("y", 0) : 0)
    width: Number(gravityRoot.renderer ? gravityRoot.renderer.prop("width", 0) : 0)
    height: Number(gravityRoot.renderer ? gravityRoot.renderer.prop("height", 0) : 0)
    magnitude: Number(gravityRoot.renderer ? gravityRoot.renderer.prop("magnitude", -10) : -10)
    angle: Number(gravityRoot.renderer ? gravityRoot.renderer.prop("angle", 90) : 90)

    onAffected: function (x, y) { gravityRoot.send("affected", { x: x, y: y }) }
    onEnabledChanged: gravityRoot.send("enabled_change", { value: nativeGravity.enabled })
  }
}
