import QtQuick
import QtQuick3D.Particles3D
import "Support" as Support
import "Support/Value3d.js" as Value3d
import "Support/Scene3dTypes.js" as Scene3dTypes

// Adds a drifting motion, shared across all particles or unique to
// each, which is what makes smoke and dust look unforced.
Wander3D {
    id: wander3d

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

    // eulerRotation and rotation describe the same orientation, so the
    // quaternion is applied only when Ruby declared one.
    Binding {
        target: wander3d
        property: "rotation"
        value: Value3d.quaternion(renderer.prop("rotation", null))
        when: renderer.hasProp("rotation")
        restoreMode: Binding.RestoreBindingOrValue
    }

    Support.Prop3dBinding {
        renderer: wander3d.renderer
        target: wander3d
        name: "global_amount"
        property: "globalAmount"
        value: Value3d.vector3d(wander3d.renderer.prop("global_amount"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: wander3d.renderer
        target: wander3d
        name: "global_pace"
        property: "globalPace"
        value: Value3d.vector3d(wander3d.renderer.prop("global_pace"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: wander3d.renderer
        target: wander3d
        name: "global_pace_start"
        property: "globalPaceStart"
        value: Value3d.vector3d(wander3d.renderer.prop("global_pace_start"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: wander3d.renderer
        target: wander3d
        name: "unique_amount"
        property: "uniqueAmount"
        value: Value3d.vector3d(wander3d.renderer.prop("unique_amount"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: wander3d.renderer
        target: wander3d
        name: "unique_pace"
        property: "uniquePace"
        value: Value3d.vector3d(wander3d.renderer.prop("unique_pace"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: wander3d.renderer
        target: wander3d
        name: "unique_amount_variation"
        property: "uniqueAmountVariation"
        value: Number(wander3d.renderer.prop("unique_amount_variation"))
    }

    Support.Prop3dBinding {
        renderer: wander3d.renderer
        target: wander3d
        name: "unique_pace_variation"
        property: "uniquePaceVariation"
        value: Number(wander3d.renderer.prop("unique_pace_variation"))
    }

    Support.Prop3dBinding {
        renderer: wander3d.renderer
        target: wander3d
        name: "fade_in_duration"
        property: "fadeInDuration"
        value: Number(wander3d.renderer.prop("fade_in_duration"))
    }

    Support.Prop3dBinding {
        renderer: wander3d.renderer
        target: wander3d
        name: "fade_out_duration"
        property: "fadeOutDuration"
        value: Number(wander3d.renderer.prop("fade_out_duration"))
    }

    Support.Prop3dBinding {
        renderer: wander3d.renderer
        target: wander3d
        name: "enabled"
        property: "enabled"
        value: wander3d.renderer.prop("enabled") === true
    }
}
