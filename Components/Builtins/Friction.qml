import QtQuick
import QtQuick.Particles

// QtQuick.Particles/Friction. Slows particles down in proportion to their
// current velocity, down to an optional threshold it never slows past.
Item {
  id: frictionRoot
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

  Friction {
    id: nativeFriction
    system: frictionRoot.particleSystem
    groups: frictionRoot.stringList(frictionRoot.renderer ? frictionRoot.renderer.prop("groups", []) : [])
    whenCollidingWith: frictionRoot.stringList(frictionRoot.renderer ? frictionRoot.renderer.prop("when_colliding_with", []) : [])
    enabled: frictionRoot.renderer ? frictionRoot.renderer.prop("enabled", true) !== false : true
    once: frictionRoot.renderer ? frictionRoot.renderer.prop("once", false) === true : false
    shape: frictionRoot.affectedArea ? frictionRoot.affectedArea : uniformArea
    x: Number(frictionRoot.renderer ? frictionRoot.renderer.prop("x", 0) : 0)
    y: Number(frictionRoot.renderer ? frictionRoot.renderer.prop("y", 0) : 0)
    width: Number(frictionRoot.renderer ? frictionRoot.renderer.prop("width", 0) : 0)
    height: Number(frictionRoot.renderer ? frictionRoot.renderer.prop("height", 0) : 0)
    factor: Number(frictionRoot.renderer ? frictionRoot.renderer.prop("factor", 0) : 0)
    threshold: Number(frictionRoot.renderer ? frictionRoot.renderer.prop("threshold", 0) : 0)

    onAffected: function (x, y) { frictionRoot.send("affected", { x: x, y: y }) }
    onEnabledChanged: frictionRoot.send("enabled_change", { value: nativeFriction.enabled })
  }
}
