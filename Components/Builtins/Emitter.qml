import QtQuick
import QtQuick.Particles

// QtQuick.Particles/Emitter. Emits into a particle system referenced by control
// id, so one system can be fed by several independently configured emitters.
//
// `shape`, `velocity` and `acceleration` reference a shape or direction
// component by control id. Qt dereferences those three without a null check, so
// an unset or unresolved reference falls back to a neutral local object that
// reproduces Qt's own default: uniform extrusion over the emitter area and a
// zero vector.
Item {
  id: emitterRoot
  property var renderer: null
  property int handledBurstRevision: -1
  property int handledPulseRevision: -1

  readonly property var particleSystem: nativeHandle(renderer ? renderer.prop("system", "") : "", "nativeParticleSystem")
  readonly property var emissionShape: nativeHandle(renderer ? renderer.prop("shape", "") : "", "nativeExtruder")
  readonly property var velocityDirection: nativeHandle(renderer ? renderer.prop("velocity", "") : "", "nativeDirection")
  readonly property var accelerationDirection: nativeHandle(renderer ? renderer.prop("acceleration", "") : "", "nativeDirection")

  function nativeHandle(controlId, handle) {
    var name = String(controlId || "")
    if (!renderer || name === "") return null
    var host = renderer.findRenderedItem(name)
    if (!host) return null
    var value = host[handle]
    return value === undefined ? null : value
  }

  function send(name, payload) {
    if (renderer && renderer.subscribed(name)) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }

  function handleBurst() {
    if (!renderer) return
    var revision = Number(renderer.prop("burst_revision", 0))
    var count = Number(renderer.prop("burst_count", 0))
    if (revision === handledBurstRevision || count <= 0) return
    handledBurstRevision = revision
    nativeEmitter.burst(count, Number(renderer.prop("burst_x", nativeEmitter.width / 2)),
      Number(renderer.prop("burst_y", nativeEmitter.height / 2)))
    send("burst", { count: count, revision: revision })
  }

  function handlePulse() {
    if (!renderer) return
    var revision = Number(renderer.prop("pulse_revision", 0))
    var duration = Number(renderer.prop("pulse_duration", 0))
    if (revision === handledPulseRevision || duration <= 0) return
    handledPulseRevision = revision
    nativeEmitter.pulse(duration)
    send("pulse", { duration: duration, revision: revision })
  }

  // Qt's own defaults, kept as real objects because Emitter dereferences these
  // three properties without a null check.
  RectangleShape { id: uniformArea; fill: true }
  AngleDirection { id: zeroVelocity }
  AngleDirection { id: zeroAcceleration }

  Emitter {
    id: nativeEmitter
    system: emitterRoot.particleSystem
    group: String(emitterRoot.renderer ? emitterRoot.renderer.prop("group", "") : "")
    shape: emitterRoot.emissionShape ? emitterRoot.emissionShape : uniformArea
    velocity: emitterRoot.velocityDirection ? emitterRoot.velocityDirection : zeroVelocity
    acceleration: emitterRoot.accelerationDirection ? emitterRoot.accelerationDirection : zeroAcceleration
    enabled: emitterRoot.renderer ? emitterRoot.renderer.prop("enabled", true) !== false : true
    startTime: Number(emitterRoot.renderer ? emitterRoot.renderer.prop("start_time", 0) : 0)
    emitRate: Number(emitterRoot.renderer ? emitterRoot.renderer.prop("emit_rate", 10) : 10)
    lifeSpan: Number(emitterRoot.renderer ? emitterRoot.renderer.prop("life_span", 1000) : 1000)
    lifeSpanVariation: Number(emitterRoot.renderer ? emitterRoot.renderer.prop("life_span_variation", 0) : 0)
    maximumEmitted: Number(emitterRoot.renderer ? emitterRoot.renderer.prop("maximum_emitted", -1) : -1)
    size: Number(emitterRoot.renderer ? emitterRoot.renderer.prop("size", 16) : 16)
    endSize: Number(emitterRoot.renderer ? emitterRoot.renderer.prop("end_size", -1) : -1)
    sizeVariation: Number(emitterRoot.renderer ? emitterRoot.renderer.prop("size_variation", 0) : 0)
    velocityFromMovement: Number(emitterRoot.renderer ? emitterRoot.renderer.prop("velocity_from_movement", 0) : 0)
    x: Number(emitterRoot.renderer ? emitterRoot.renderer.prop("x", 0) : 0)
    y: Number(emitterRoot.renderer ? emitterRoot.renderer.prop("y", 0) : 0)
    width: Number(emitterRoot.renderer ? emitterRoot.renderer.prop("width", 0) : 0)
    height: Number(emitterRoot.renderer ? emitterRoot.renderer.prop("height", 0) : 0)

    onEmitParticles: function (particles) {
      emitterRoot.send("emit", { count: particles ? particles.length : 0 })
    }
    onEnabledChanged: emitterRoot.send("enabled_change", { value: nativeEmitter.enabled })
    onParticleCountChanged: emitterRoot.send("count_change", {})
  }

  Connections {
    target: emitterRoot.renderer
    function onNodeChanged() { emitterRoot.handleBurst(); emitterRoot.handlePulse() }
  }
  Component.onCompleted: { handleBurst(); handlePulse() }
}
