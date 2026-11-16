import QtQuick
import QtQuick.Particles

// QtQuick.Particles/SpriteGoal. Moves the particles it affects toward a sprite
// state, so entering an area can change how a particle is drawn.
//
// Qt deprecates `systemStates` and warns on every assignment, so it is only
// applied when an application actually asks for it. Use group_goal instead.
Item {
  id: spriteGoalRoot
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

  SpriteGoal {
    id: nativeSpriteGoal
    system: spriteGoalRoot.particleSystem
    groups: spriteGoalRoot.stringList(spriteGoalRoot.renderer ? spriteGoalRoot.renderer.prop("groups", []) : [])
    whenCollidingWith: spriteGoalRoot.stringList(spriteGoalRoot.renderer ? spriteGoalRoot.renderer.prop("when_colliding_with", []) : [])
    enabled: spriteGoalRoot.renderer ? spriteGoalRoot.renderer.prop("enabled", true) !== false : true
    once: spriteGoalRoot.renderer ? spriteGoalRoot.renderer.prop("once", false) === true : false
    shape: spriteGoalRoot.affectedArea ? spriteGoalRoot.affectedArea : uniformArea
    x: Number(spriteGoalRoot.renderer ? spriteGoalRoot.renderer.prop("x", 0) : 0)
    y: Number(spriteGoalRoot.renderer ? spriteGoalRoot.renderer.prop("y", 0) : 0)
    width: Number(spriteGoalRoot.renderer ? spriteGoalRoot.renderer.prop("width", 0) : 0)
    height: Number(spriteGoalRoot.renderer ? spriteGoalRoot.renderer.prop("height", 0) : 0)
    goalState: String(spriteGoalRoot.renderer ? spriteGoalRoot.renderer.prop("goal_state", "") : "")
    jump: spriteGoalRoot.renderer ? spriteGoalRoot.renderer.prop("jump", false) === true : false

    onAffected: function (x, y) { spriteGoalRoot.send("affected", { x: x, y: y }) }
    onEnabledChanged: spriteGoalRoot.send("enabled_change", { value: nativeSpriteGoal.enabled })
  }

  Binding {
    target: nativeSpriteGoal
    property: "systemStates"
    value: spriteGoalRoot.renderer ? spriteGoalRoot.renderer.prop("system_states", false) === true : false
    when: spriteGoalRoot.renderer ? spriteGoalRoot.renderer.hasProp("system_states") : false
  }
}
