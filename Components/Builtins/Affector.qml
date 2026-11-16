import QtQuick
import QtQuick.Particles

// QtQuick.Particles/Affector. Qt's general-purpose affector: it offsets a
// particle's position, velocity and acceleration by the directions it is given,
// either relative to the current value or as an absolute replacement.
//
// `position`, `velocity` and `acceleration` reference a direction component by
// control id.
Item {
  id: affectorRoot
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

  readonly property var positionDirection: nativeHandle(renderer ? renderer.prop("position", "") : "", "nativeDirection")
  readonly property var velocityDirection: nativeHandle(renderer ? renderer.prop("velocity", "") : "", "nativeDirection")
  readonly property var accelerationDirection: nativeHandle(renderer ? renderer.prop("acceleration", "") : "", "nativeDirection")

  // Qt hands Affector real direction objects, so an unset or unresolved
  // reference falls back to a zero vector rather than null.
  AngleDirection { id: zeroPosition }
  AngleDirection { id: zeroVelocity }
  AngleDirection { id: zeroAcceleration }

  // Qt hands every affector a real extruder covering its whole area, so an
  // unset or unresolved shape falls back to the same thing rather than null.
  RectangleShape { id: uniformArea; fill: true }

  Affector {
    id: nativeAffector
    system: affectorRoot.particleSystem
    groups: affectorRoot.stringList(affectorRoot.renderer ? affectorRoot.renderer.prop("groups", []) : [])
    whenCollidingWith: affectorRoot.stringList(affectorRoot.renderer ? affectorRoot.renderer.prop("when_colliding_with", []) : [])
    enabled: affectorRoot.renderer ? affectorRoot.renderer.prop("enabled", true) !== false : true
    once: affectorRoot.renderer ? affectorRoot.renderer.prop("once", false) === true : false
    shape: affectorRoot.affectedArea ? affectorRoot.affectedArea : uniformArea
    x: Number(affectorRoot.renderer ? affectorRoot.renderer.prop("x", 0) : 0)
    y: Number(affectorRoot.renderer ? affectorRoot.renderer.prop("y", 0) : 0)
    width: Number(affectorRoot.renderer ? affectorRoot.renderer.prop("width", 0) : 0)
    height: Number(affectorRoot.renderer ? affectorRoot.renderer.prop("height", 0) : 0)
    relative: affectorRoot.renderer ? affectorRoot.renderer.prop("relative", true) !== false : true
    position: affectorRoot.positionDirection ? affectorRoot.positionDirection : zeroPosition
    velocity: affectorRoot.velocityDirection ? affectorRoot.velocityDirection : zeroVelocity
    acceleration: affectorRoot.accelerationDirection ? affectorRoot.accelerationDirection : zeroAcceleration

    onAffected: function (x, y) { affectorRoot.send("affected", { x: x, y: y }) }
    onEnabledChanged: affectorRoot.send("enabled_change", { value: nativeAffector.enabled })
  }
}
