import QtQuick
import QtQuick.Particles

// QtQuick.Particles/GroupGoal. Moves the particles it affects toward another
// particle group, so entering an area can change what a particle becomes.
Item {
  id: groupGoalRoot
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

  GroupGoal {
    id: nativeGroupGoal
    system: groupGoalRoot.particleSystem
    groups: groupGoalRoot.stringList(groupGoalRoot.renderer ? groupGoalRoot.renderer.prop("groups", []) : [])
    whenCollidingWith: groupGoalRoot.stringList(groupGoalRoot.renderer ? groupGoalRoot.renderer.prop("when_colliding_with", []) : [])
    enabled: groupGoalRoot.renderer ? groupGoalRoot.renderer.prop("enabled", true) !== false : true
    once: groupGoalRoot.renderer ? groupGoalRoot.renderer.prop("once", false) === true : false
    shape: groupGoalRoot.affectedArea ? groupGoalRoot.affectedArea : uniformArea
    x: Number(groupGoalRoot.renderer ? groupGoalRoot.renderer.prop("x", 0) : 0)
    y: Number(groupGoalRoot.renderer ? groupGoalRoot.renderer.prop("y", 0) : 0)
    width: Number(groupGoalRoot.renderer ? groupGoalRoot.renderer.prop("width", 0) : 0)
    height: Number(groupGoalRoot.renderer ? groupGoalRoot.renderer.prop("height", 0) : 0)
    goalState: String(groupGoalRoot.renderer ? groupGoalRoot.renderer.prop("goal_state", "") : "")
    jump: groupGoalRoot.renderer ? groupGoalRoot.renderer.prop("jump", false) === true : false

    onAffected: function (x, y) { groupGoalRoot.send("affected", { x: x, y: y }) }
    onEnabledChanged: groupGoalRoot.send("enabled_change", { value: nativeGroupGoal.enabled })
  }
}
