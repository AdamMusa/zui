import QtQuick
import QtQuick3D.Particles3D
import "Support" as Support
import "Support/Value3d.js" as Value3d
import "Support/Scene3dTypes.js" as Scene3dTypes

// Pulls particles towards a position or towards points on a shape, so a
// cloud of particles gathers into a form over a given duration.
Attractor3D {
    id: attractor3d

    required property var renderer

    position: Value3d.vector3d(renderer.prop("position", null), renderer.prop("x", 0), renderer.prop("y", 0), renderer.prop("z", 0))
    eulerRotation: Value3d.vector3d(renderer.prop("euler_rotation", null), renderer.prop("rotation_x", 0), renderer.prop("rotation_y", 0), renderer.prop("rotation_z", 0))
    scale: Value3d.vector3d(renderer.prop("scale", null), 1, 1, 1)
    pivot: Value3d.vector3d(renderer.prop("pivot", null), 0, 0, 0)
    opacity: Number(renderer.prop("opacity", 1))
    visible: renderer.prop("visible", true) !== false
    staticFlags: Number(renderer.prop("static_flags", 0))
    system: renderer.ownerOrReference(Scene3dTypes.particleSystems, "system")
    particles: renderer.sceneObjects(renderer.prop("particles", []))
    shape: renderer.childObjectOrReference(Scene3dTypes.particleShapes, "shape")

    // eulerRotation and rotation describe the same orientation, so the
    // quaternion is applied only when Ruby declared one.
    Binding {
        target: attractor3d
        property: "rotation"
        value: Value3d.quaternion(renderer.prop("rotation", null))
        when: renderer.hasProp("rotation")
        restoreMode: Binding.RestoreBindingOrValue
    }

    Support.Prop3dBinding {
        renderer: attractor3d.renderer
        target: attractor3d
        name: "position_variation"
        property: "positionVariation"
        value: Value3d.vector3d(attractor3d.renderer.prop("position_variation"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: attractor3d.renderer
        target: attractor3d
        name: "duration"
        property: "duration"
        value: Number(attractor3d.renderer.prop("duration"))
    }

    Support.Prop3dBinding {
        renderer: attractor3d.renderer
        target: attractor3d
        name: "duration_variation"
        property: "durationVariation"
        value: Number(attractor3d.renderer.prop("duration_variation"))
    }

    Support.Prop3dBinding {
        renderer: attractor3d.renderer
        target: attractor3d
        name: "hide_at_end"
        property: "hideAtEnd"
        value: attractor3d.renderer.prop("hide_at_end") === true
    }

    Support.Prop3dBinding {
        renderer: attractor3d.renderer
        target: attractor3d
        name: "use_cached_positions"
        property: "useCachedPositions"
        value: attractor3d.renderer.prop("use_cached_positions") === true
    }

    Support.Prop3dBinding {
        renderer: attractor3d.renderer
        target: attractor3d
        name: "positions_amount"
        property: "positionsAmount"
        value: Number(attractor3d.renderer.prop("positions_amount"))
    }

    Support.Prop3dBinding {
        renderer: attractor3d.renderer
        target: attractor3d
        name: "enabled"
        property: "enabled"
        value: attractor3d.renderer.prop("enabled") === true
    }
}
