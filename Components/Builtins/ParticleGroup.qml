import QtQuick
import QtQuick.Particles

// QtQuick.Particles/ParticleGroup. Gives a named group its own lifetime and the
// weighted transitions a particle takes when that lifetime runs out, so a
// system can model stages such as spark then smoke then ember.
//
// `to` is a map of group name to relative weight. A group with no `to` entries
// simply dies when its duration elapses.
Item {
  id: particleGroupRoot
  property var renderer: null
  readonly property var nativeParticleGroup: nativeGroup

  readonly property var particleSystem: nativeHandle(renderer ? renderer.prop("system", "") : "", "nativeParticleSystem")

  function nativeHandle(controlId, handle) {
    var name = String(controlId || "")
    if (!renderer || name === "") return null
    var host = renderer.findRenderedItem(name)
    if (!host) return null
    var value = host[handle]
    return value === undefined ? null : value
  }

  function transitions() {
    var value = renderer ? renderer.prop("to", {}) : {}
    if (!value || typeof value !== "object" || Array.isArray(value)) return ({})
    var weights = ({})
    for (var group in value) weights[String(group)] = Number(value[group])
    return weights
  }

  function send(name, payload) {
    if (renderer && renderer.subscribed(name)) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }

  ParticleGroup {
    id: nativeGroup
    system: particleGroupRoot.particleSystem
    name: String(particleGroupRoot.renderer ? particleGroupRoot.renderer.prop("name", "") : "")
    duration: Number(particleGroupRoot.renderer ? particleGroupRoot.renderer.prop("duration", 1000) : 1000)
    durationVariation: Number(particleGroupRoot.renderer ? particleGroupRoot.renderer.prop("duration_variation", 0) : 0)
    randomStart: particleGroupRoot.renderer ? particleGroupRoot.renderer.prop("random_start", false) === true : false
    to: particleGroupRoot.transitions()

    onEntered: particleGroupRoot.send("enter", { group: nativeGroup.name })
  }
}
