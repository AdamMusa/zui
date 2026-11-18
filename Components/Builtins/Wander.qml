import QtQuick
import QtQuick.Particles

// QtQuick.Particles/Wander. Adds a random drift so a group does not travel in
// straight lines.
//
// `affected_parameter` is "position", "velocity" or "acceleration".
Item {
  id: wanderRoot
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

  function affectedParameterValue() {
    var parameter = String(renderer ? renderer.prop("affected_parameter", "velocity") : "velocity")
    if (parameter === "position") return Wander.Position
    if (parameter === "acceleration") return Wander.Acceleration
    return Wander.Velocity
  }

  // Qt hands every affector a real extruder covering its whole area, so an
  // unset or unresolved shape falls back to the same thing rather than null.
  RectangleShape { id: uniformArea; fill: true }

  Wander {
    id: nativeWander
    system: wanderRoot.particleSystem
    groups: wanderRoot.stringList(wanderRoot.renderer ? wanderRoot.renderer.prop("groups", []) : [])
    whenCollidingWith: wanderRoot.stringList(wanderRoot.renderer ? wanderRoot.renderer.prop("when_colliding_with", []) : [])
    enabled: wanderRoot.renderer ? wanderRoot.renderer.prop("enabled", true) !== false : true
    once: wanderRoot.renderer ? wanderRoot.renderer.prop("once", false) === true : false
    shape: wanderRoot.affectedArea ? wanderRoot.affectedArea : uniformArea
    x: Number(wanderRoot.renderer ? wanderRoot.renderer.prop("x", 0) : 0)
    y: Number(wanderRoot.renderer ? wanderRoot.renderer.prop("y", 0) : 0)
    width: Number(wanderRoot.renderer ? wanderRoot.renderer.prop("width", 0) : 0)
    height: Number(wanderRoot.renderer ? wanderRoot.renderer.prop("height", 0) : 0)
    pace: Number(wanderRoot.renderer ? wanderRoot.renderer.prop("pace", 0) : 0)
    xVariance: Number(wanderRoot.renderer ? wanderRoot.renderer.prop("x_variance", 0) : 0)
    yVariance: Number(wanderRoot.renderer ? wanderRoot.renderer.prop("y_variance", 0) : 0)
    affectedParameter: wanderRoot.affectedParameterValue()

    onAffected: function (x, y) { wanderRoot.send("affected", { x: x, y: y }) }
    onEnabledChanged: wanderRoot.send("enabled_change", { value: nativeWander.enabled })
  }
}
