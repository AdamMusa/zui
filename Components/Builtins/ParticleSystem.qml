import QtQuick
import QtQuick.Particles

Item {
  id: particleRoot
  required property var renderer
  property int handledBurstRevision: -1
  implicitWidth: Number(renderer.prop("width", 320))
  implicitHeight: Number(renderer.prop("height", 200))

  function send(name, payload) {
    if (renderer.subscribed(name)) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }

  function handleBurst() {
    var revision = Number(renderer.prop("burst_revision", 0))
    var count = Number(renderer.prop("burst_count", 0))
    if (revision === handledBurstRevision || count <= 0) return
    handledBurstRevision = revision
    particleEmitter.burst(count, Number(renderer.prop("burst_x", particleEmitter.width / 2)), Number(renderer.prop("burst_y", particleEmitter.height / 2)))
    send("burst", { count: count, revision: revision })
  }

  ParticleSystem {
    id: nativeSystem
    anchors.fill: parent
    running: renderer.prop("running", true) !== false
    paused: renderer.prop("paused", false) === true
    onRunningChanged: particleRoot.send(running ? "start" : "stop", {})
    onPausedChanged: particleRoot.send(paused ? "pause" : "resume", {})
    onEmptyChanged: if (empty) particleRoot.send("empty", {})

    Emitter {
      id: particleEmitter
      system: nativeSystem
      x: Number(renderer.prop("emitter_x", 0)); y: Number(renderer.prop("emitter_y", 0))
      width: Number(renderer.prop("emitter_width", particleRoot.width)); height: Number(renderer.prop("emitter_height", particleRoot.height))
      emitRate: Number(renderer.prop("emit_rate", 40))
      lifeSpan: Number(renderer.prop("life_span", 1500)); lifeSpanVariation: Number(renderer.prop("life_span_variation", 0))
      maximumEmitted: Number(renderer.prop("maximum_emitted", -1))
      size: Number(renderer.prop("size", 16)); endSize: Number(renderer.prop("end_size", size)); sizeVariation: Number(renderer.prop("size_variation", 0))
      shape: String(renderer.prop("particle_shape", "rectangle")) === "ellipse" ? ellipseShape : rectangleShape
      velocity: AngleDirection {
        angle: Number(renderer.prop("velocity_angle", 270)); magnitude: Number(renderer.prop("velocity", 50))
        angleVariation: Number(renderer.prop("velocity_angle_variation", 180)); magnitudeVariation: Number(renderer.prop("velocity_variation", 0))
      }
      acceleration: AngleDirection {
        angle: Number(renderer.prop("acceleration_angle", 90)); magnitude: Number(renderer.prop("acceleration", 0))
        angleVariation: Number(renderer.prop("acceleration_angle_variation", 0)); magnitudeVariation: Number(renderer.prop("acceleration_variation", 0))
      }
    }

    EllipseShape { id: ellipseShape }
    RectangleShape { id: rectangleShape; fill: true }

    ImageParticle {
      system: nativeSystem
      source: renderer.assetUrl(renderer.prop("source", ""))
      color: renderer.prop("color", "white"); colorVariation: Number(renderer.prop("color_variation", 0))
      alpha: Number(renderer.prop("alpha", 1)); alphaVariation: Number(renderer.prop("alpha_variation", 0))
      rotation: Number(renderer.prop("rotation", 0)); rotationVariation: Number(renderer.prop("rotation_variation", 0))
      rotationVelocity: Number(renderer.prop("rotation_velocity", 0)); rotationVelocityVariation: Number(renderer.prop("rotation_velocity_variation", 0))
      autoRotation: renderer.prop("auto_rotation", false) === true
    }

    Gravity {
      system: nativeSystem
      magnitude: Number(renderer.prop("gravity", 0)); angle: Number(renderer.prop("gravity_angle", 90))
    }
    Turbulence {
      system: nativeSystem
      enabled: Number(renderer.prop("turbulence", 0)) !== 0
      strength: Number(renderer.prop("turbulence", 0))
      x: Number(renderer.prop("turbulence_x", 0)); y: Number(renderer.prop("turbulence_y", 0))
      width: Number(renderer.prop("turbulence_width", particleRoot.width)); height: Number(renderer.prop("turbulence_height", particleRoot.height))
    }
  }

  Connections { target: renderer; function onNodeChanged() { particleRoot.handleBurst() } }
  Component.onCompleted: handleBurst()
}
