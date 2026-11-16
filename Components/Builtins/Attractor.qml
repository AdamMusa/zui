import QtQuick
import QtQuick.Particles

// QtQuick.Particles/Attractor. Pulls particles toward a point, optionally
// falling off with distance.
//
// `affected_parameter` is "position", "velocity" or "acceleration".
// `proportional_to_distance` is "constant", "linear", "quadratic",
// "inverse_linear" or "inverse_quadratic".
Item {
  id: attractorRoot
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
    if (parameter === "position") return Attractor.Position
    if (parameter === "acceleration") return Attractor.Acceleration
    return Attractor.Velocity
  }

  function proportionValue() {
    var proportion = String(renderer ? renderer.prop("proportional_to_distance", "linear") : "linear")
    if (proportion === "constant") return Attractor.Constant
    if (proportion === "quadratic") return Attractor.Quadratic
    if (proportion === "inverse_linear") return Attractor.InverseLinear
    if (proportion === "inverse_quadratic") return Attractor.InverseQuadratic
    return Attractor.Linear
  }

  // Qt hands every affector a real extruder covering its whole area, so an
  // unset or unresolved shape falls back to the same thing rather than null.
  RectangleShape { id: uniformArea; fill: true }

  Attractor {
    id: nativeAttractor
    system: attractorRoot.particleSystem
    groups: attractorRoot.stringList(attractorRoot.renderer ? attractorRoot.renderer.prop("groups", []) : [])
    whenCollidingWith: attractorRoot.stringList(attractorRoot.renderer ? attractorRoot.renderer.prop("when_colliding_with", []) : [])
    enabled: attractorRoot.renderer ? attractorRoot.renderer.prop("enabled", true) !== false : true
    once: attractorRoot.renderer ? attractorRoot.renderer.prop("once", false) === true : false
    shape: attractorRoot.affectedArea ? attractorRoot.affectedArea : uniformArea
    x: Number(attractorRoot.renderer ? attractorRoot.renderer.prop("x", 0) : 0)
    y: Number(attractorRoot.renderer ? attractorRoot.renderer.prop("y", 0) : 0)
    width: Number(attractorRoot.renderer ? attractorRoot.renderer.prop("width", 0) : 0)
    height: Number(attractorRoot.renderer ? attractorRoot.renderer.prop("height", 0) : 0)
    strength: Number(attractorRoot.renderer ? attractorRoot.renderer.prop("strength", 0) : 0)
    pointX: Number(attractorRoot.renderer ? attractorRoot.renderer.prop("point_x", 0) : 0)
    pointY: Number(attractorRoot.renderer ? attractorRoot.renderer.prop("point_y", 0) : 0)
    affectedParameter: attractorRoot.affectedParameterValue()
    proportionalToDistance: attractorRoot.proportionValue()

    onAffected: function (x, y) { attractorRoot.send("affected", { x: x, y: y }) }
    onEnabledChanged: attractorRoot.send("enabled_change", { value: nativeAttractor.enabled })
  }
}
