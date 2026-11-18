import QtQuick
import QtQuick.Particles

// QtQuick.Particles/Age. Cuts a particle's remaining life short, so a group can
// be aged out of an area instead of waiting for its life span.
//
// Qt's Age.InfiniteLife constant is declared in the type but not reachable from
// QML in 6.8.3, so `life_left` takes a plain duration in milliseconds.
Item {
  id: ageRoot
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

  Age {
    id: nativeAge
    system: ageRoot.particleSystem
    groups: ageRoot.stringList(ageRoot.renderer ? ageRoot.renderer.prop("groups", []) : [])
    whenCollidingWith: ageRoot.stringList(ageRoot.renderer ? ageRoot.renderer.prop("when_colliding_with", []) : [])
    enabled: ageRoot.renderer ? ageRoot.renderer.prop("enabled", true) !== false : true
    once: ageRoot.renderer ? ageRoot.renderer.prop("once", false) === true : false
    shape: ageRoot.affectedArea ? ageRoot.affectedArea : uniformArea
    x: Number(ageRoot.renderer ? ageRoot.renderer.prop("x", 0) : 0)
    y: Number(ageRoot.renderer ? ageRoot.renderer.prop("y", 0) : 0)
    width: Number(ageRoot.renderer ? ageRoot.renderer.prop("width", 0) : 0)
    height: Number(ageRoot.renderer ? ageRoot.renderer.prop("height", 0) : 0)
    lifeLeft: Number(ageRoot.renderer ? ageRoot.renderer.prop("life_left", 0) : 0)
    advancePosition: ageRoot.renderer ? ageRoot.renderer.prop("advance_position", true) !== false : true

    onAffected: function (x, y) { ageRoot.send("affected", { x: x, y: y }) }
    onEnabledChanged: ageRoot.send("enabled_change", { value: nativeAge.enabled })
  }
}
