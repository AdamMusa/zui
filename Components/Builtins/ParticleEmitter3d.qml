import QtQuick
import QtQuick3D.Particles3D
import "Support" as Support
import "Support/Value3d.js" as Value3d
import "Support/Scene3dTypes.js" as Scene3dTypes

// Spawns particles into a system: how many per second, how long they
// live, how big they start and end, and how they turn. The shape
// declared inside it decides where they appear, and the direction
// decides where they go.
ParticleEmitter3D {
    id: particleEmitter3d

    required property var renderer

    position: Value3d.vector3d(renderer.prop("position", null), renderer.prop("x", 0), renderer.prop("y", 0), renderer.prop("z", 0))
    eulerRotation: Value3d.vector3d(renderer.prop("euler_rotation", null), renderer.prop("rotation_x", 0), renderer.prop("rotation_y", 0), renderer.prop("rotation_z", 0))
    scale: Value3d.vector3d(renderer.prop("scale", null), 1, 1, 1)
    pivot: Value3d.vector3d(renderer.prop("pivot", null), 0, 0, 0)
    opacity: Number(renderer.prop("opacity", 1))
    visible: renderer.prop("visible", true) !== false
    staticFlags: Number(renderer.prop("static_flags", 0))
    system: renderer.ownerOrReference(Scene3dTypes.particleSystems, "system")
    particle: renderer.childObjectOrReference(Scene3dTypes.particles, "particle")
    shape: renderer.childObjectOrReference(Scene3dTypes.particleShapes, "shape")
    velocity: renderer.childObjectOrReference(Scene3dTypes.particleDirections, "velocity")
    emitBursts: renderer.childObjectsAndReferences(Scene3dTypes.particleBursts, "bursts")

    // eulerRotation and rotation describe the same orientation, so the
    // quaternion is applied only when Ruby declared one.
    Binding {
        target: particleEmitter3d
        property: "rotation"
        value: Value3d.quaternion(renderer.prop("rotation", null))
        when: renderer.hasProp("rotation")
        restoreMode: Binding.RestoreBindingOrValue
    }

    Support.Prop3dBinding {
        renderer: particleEmitter3d.renderer
        target: particleEmitter3d
        name: "enabled"
        property: "enabled"
        value: particleEmitter3d.renderer.prop("enabled") === true
    }

    Support.Prop3dBinding {
        renderer: particleEmitter3d.renderer
        target: particleEmitter3d
        name: "emit_rate"
        property: "emitRate"
        value: Number(particleEmitter3d.renderer.prop("emit_rate"))
    }

    Support.Prop3dBinding {
        renderer: particleEmitter3d.renderer
        target: particleEmitter3d
        name: "life_span"
        property: "lifeSpan"
        value: Number(particleEmitter3d.renderer.prop("life_span"))
    }

    Support.Prop3dBinding {
        renderer: particleEmitter3d.renderer
        target: particleEmitter3d
        name: "life_span_variation"
        property: "lifeSpanVariation"
        value: Number(particleEmitter3d.renderer.prop("life_span_variation"))
    }

    Support.Prop3dBinding {
        renderer: particleEmitter3d.renderer
        target: particleEmitter3d
        name: "particle_scale"
        property: "particleScale"
        value: Number(particleEmitter3d.renderer.prop("particle_scale"))
    }

    Support.Prop3dBinding {
        renderer: particleEmitter3d.renderer
        target: particleEmitter3d
        name: "particle_end_scale"
        property: "particleEndScale"
        value: Number(particleEmitter3d.renderer.prop("particle_end_scale"))
    }

    Support.Prop3dBinding {
        renderer: particleEmitter3d.renderer
        target: particleEmitter3d
        name: "particle_scale_variation"
        property: "particleScaleVariation"
        value: Number(particleEmitter3d.renderer.prop("particle_scale_variation"))
    }

    Support.Prop3dBinding {
        renderer: particleEmitter3d.renderer
        target: particleEmitter3d
        name: "particle_end_scale_variation"
        property: "particleEndScaleVariation"
        value: Number(particleEmitter3d.renderer.prop("particle_end_scale_variation"))
    }

    Support.Prop3dBinding {
        renderer: particleEmitter3d.renderer
        target: particleEmitter3d
        name: "particle_rotation"
        property: "particleRotation"
        value: Value3d.vector3d(particleEmitter3d.renderer.prop("particle_rotation"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: particleEmitter3d.renderer
        target: particleEmitter3d
        name: "particle_rotation_variation"
        property: "particleRotationVariation"
        value: Value3d.vector3d(particleEmitter3d.renderer.prop("particle_rotation_variation"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: particleEmitter3d.renderer
        target: particleEmitter3d
        name: "particle_rotation_velocity"
        property: "particleRotationVelocity"
        value: Value3d.vector3d(particleEmitter3d.renderer.prop("particle_rotation_velocity"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: particleEmitter3d.renderer
        target: particleEmitter3d
        name: "particle_rotation_velocity_variation"
        property: "particleRotationVelocityVariation"
        value: Value3d.vector3d(particleEmitter3d.renderer.prop("particle_rotation_velocity_variation"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: particleEmitter3d.renderer
        target: particleEmitter3d
        name: "depth_bias"
        property: "depthBias"
        value: Number(particleEmitter3d.renderer.prop("depth_bias"))
    }
}
