import QtQuick
import QtQuick3D.Particles3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// A GPU particle system. The particles it can draw, the emitters that
// spawn them and the affectors that push them around are all declared
// inside it, and its time can be driven from Ruby instead of the clock.
ParticleSystem3D {
    id: particleSystem3d

    required property var renderer

    position: Value3d.vector3d(renderer.prop("position", null), renderer.prop("x", 0), renderer.prop("y", 0), renderer.prop("z", 0))
    eulerRotation: Value3d.vector3d(renderer.prop("euler_rotation", null), renderer.prop("rotation_x", 0), renderer.prop("rotation_y", 0), renderer.prop("rotation_z", 0))
    scale: Value3d.vector3d(renderer.prop("scale", null), 1, 1, 1)
    pivot: Value3d.vector3d(renderer.prop("pivot", null), 0, 0, 0)
    opacity: Number(renderer.prop("opacity", 1))
    visible: renderer.prop("visible", true) !== false
    staticFlags: Number(renderer.prop("static_flags", 0))

    // eulerRotation and rotation describe the same orientation, so the
    // quaternion is applied only when Ruby declared one.
    Binding {
        target: particleSystem3d
        property: "rotation"
        value: Value3d.quaternion(renderer.prop("rotation", null))
        when: renderer.hasProp("rotation")
        restoreMode: Binding.RestoreBindingOrValue
    }

    Support.Prop3dBinding {
        renderer: particleSystem3d.renderer
        target: particleSystem3d
        name: "running"
        property: "running"
        value: particleSystem3d.renderer.prop("running") === true
    }

    Support.Prop3dBinding {
        renderer: particleSystem3d.renderer
        target: particleSystem3d
        name: "paused"
        property: "paused"
        value: particleSystem3d.renderer.prop("paused") === true
    }

    Support.Prop3dBinding {
        renderer: particleSystem3d.renderer
        target: particleSystem3d
        name: "start_time"
        property: "startTime"
        value: Number(particleSystem3d.renderer.prop("start_time"))
    }

    Support.Prop3dBinding {
        renderer: particleSystem3d.renderer
        target: particleSystem3d
        name: "time"
        property: "time"
        value: Number(particleSystem3d.renderer.prop("time"))
    }

    Support.Prop3dBinding {
        renderer: particleSystem3d.renderer
        target: particleSystem3d
        name: "use_random_seed"
        property: "useRandomSeed"
        value: particleSystem3d.renderer.prop("use_random_seed") === true
    }

    Support.Prop3dBinding {
        renderer: particleSystem3d.renderer
        target: particleSystem3d
        name: "seed"
        property: "seed"
        value: Number(particleSystem3d.renderer.prop("seed"))
    }

    Support.Prop3dBinding {
        renderer: particleSystem3d.renderer
        target: particleSystem3d
        name: "logging"
        property: "logging"
        value: particleSystem3d.renderer.prop("logging") === true
    }
}
