import QtQuick
import QtQuick.Particles

// QtQuick.Particles/TrailEmitter. An emitter that follows the particles of
// another group instead of a fixed area, so one group can trail another.
//
// `shape`, `velocity`, `acceleration` and `emit_shape` reference a shape or
// direction component by control id. Qt dereferences those without a null
// check, so an unset or unresolved reference falls back to a neutral local
// object that reproduces Qt's own default.
//
// `emit_width` and `emit_height` accept "particle_size" for
// TrailEmitter.ParticleSize, which is also the default.
Item {
  id: trailEmitterRoot
  property var renderer: null
  property int handledBurstRevision: -1
  property int handledPulseRevision: -1

  readonly property var particleSystem: nativeHandle(renderer ? renderer.prop("system", "") : "", "nativeParticleSystem")
  readonly property var emissionShape: nativeHandle(renderer ? renderer.prop("shape", "") : "", "nativeExtruder")
  readonly property var followShape: nativeHandle(renderer ? renderer.prop("emit_shape", "") : "", "nativeExtruder")
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

  function emitExtent(name) {
    var value = renderer ? renderer.prop(name, "particle_size") : "particle_size"
    return String(value) === "particle_size" ? TrailEmitter.ParticleSize : Number(value)
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
    nativeTrailEmitter.burst(count, Number(renderer.prop("burst_x", nativeTrailEmitter.width / 2)),
      Number(renderer.prop("burst_y", nativeTrailEmitter.height / 2)))
    send("burst", { count: count, revision: revision })
  }

  function handlePulse() {
    if (!renderer) return
    var revision = Number(renderer.prop("pulse_revision", 0))
    var duration = Number(renderer.prop("pulse_duration", 0))
    if (revision === handledPulseRevision || duration <= 0) return
    handledPulseRevision = revision
    nativeTrailEmitter.pulse(duration)
    send("pulse", { duration: duration, revision: revision })
  }

  RectangleShape { id: uniformArea; fill: true }
  RectangleShape { id: uniformFollowArea; fill: true }
  AngleDirection { id: zeroVelocity }
  AngleDirection { id: zeroAcceleration }

  TrailEmitter {
    id: nativeTrailEmitter
    system: trailEmitterRoot.particleSystem
    group: String(trailEmitterRoot.renderer ? trailEmitterRoot.renderer.prop("group", "") : "")
    follow: String(trailEmitterRoot.renderer ? trailEmitterRoot.renderer.prop("follow", "") : "")
    shape: trailEmitterRoot.emissionShape ? trailEmitterRoot.emissionShape : uniformArea
    emitShape: trailEmitterRoot.followShape ? trailEmitterRoot.followShape : uniformFollowArea
    velocity: trailEmitterRoot.velocityDirection ? trailEmitterRoot.velocityDirection : zeroVelocity
    acceleration: trailEmitterRoot.accelerationDirection ? trailEmitterRoot.accelerationDirection : zeroAcceleration
    emitRatePerParticle: Number(trailEmitterRoot.renderer ? trailEmitterRoot.renderer.prop("emit_rate_per_particle", 0) : 0)
    emitWidth: trailEmitterRoot.emitExtent("emit_width")
    emitHeight: trailEmitterRoot.emitExtent("emit_height")
    enabled: trailEmitterRoot.renderer ? trailEmitterRoot.renderer.prop("enabled", true) !== false : true
    startTime: Number(trailEmitterRoot.renderer ? trailEmitterRoot.renderer.prop("start_time", 0) : 0)
    emitRate: Number(trailEmitterRoot.renderer ? trailEmitterRoot.renderer.prop("emit_rate", 10) : 10)
    lifeSpan: Number(trailEmitterRoot.renderer ? trailEmitterRoot.renderer.prop("life_span", 1000) : 1000)
    lifeSpanVariation: Number(trailEmitterRoot.renderer ? trailEmitterRoot.renderer.prop("life_span_variation", 0) : 0)
    maximumEmitted: Number(trailEmitterRoot.renderer ? trailEmitterRoot.renderer.prop("maximum_emitted", -1) : -1)
    size: Number(trailEmitterRoot.renderer ? trailEmitterRoot.renderer.prop("size", 16) : 16)
    endSize: Number(trailEmitterRoot.renderer ? trailEmitterRoot.renderer.prop("end_size", -1) : -1)
    sizeVariation: Number(trailEmitterRoot.renderer ? trailEmitterRoot.renderer.prop("size_variation", 0) : 0)
    velocityFromMovement: Number(trailEmitterRoot.renderer ? trailEmitterRoot.renderer.prop("velocity_from_movement", 0) : 0)
    x: Number(trailEmitterRoot.renderer ? trailEmitterRoot.renderer.prop("x", 0) : 0)
    y: Number(trailEmitterRoot.renderer ? trailEmitterRoot.renderer.prop("y", 0) : 0)
    width: Number(trailEmitterRoot.renderer ? trailEmitterRoot.renderer.prop("width", 0) : 0)
    height: Number(trailEmitterRoot.renderer ? trailEmitterRoot.renderer.prop("height", 0) : 0)

    onEmitParticles: function (particles) {
      trailEmitterRoot.send("emit", { count: particles ? particles.length : 0 })
    }
    onEmitFollowParticles: function (particles, followed) {
      trailEmitterRoot.send("emit_follow", { count: particles ? particles.length : 0 })
    }
    onEnabledChanged: trailEmitterRoot.send("enabled_change", { value: nativeTrailEmitter.enabled })
    onParticleCountChanged: trailEmitterRoot.send("count_change", {})
  }

  Connections {
    target: trailEmitterRoot.renderer
    function onNodeChanged() { trailEmitterRoot.handleBurst(); trailEmitterRoot.handlePulse() }
  }
  Component.onCompleted: { handleBurst(); handlePulse() }
}
