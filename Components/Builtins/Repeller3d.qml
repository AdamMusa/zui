import QtQuick
import QtQuick3D.Particles3D
import "Support" as Support
import "Support/Value3d.js" as Value3d
import "Support/Scene3dTypes.js" as Scene3dTypes

// Pushes particles away from its position, fading between an inner and
// an outer radius, so geometry can appear to part the flow.
Repeller3D {
    id: repeller3d

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
        target: repeller3d
        property: "rotation"
        value: Value3d.quaternion(renderer.prop("rotation", null))
        when: renderer.hasProp("rotation")
        restoreMode: Binding.RestoreBindingOrValue
    }

    Support.Prop3dBinding {
        renderer: repeller3d.renderer
        target: repeller3d
        name: "radius"
        property: "radius"
        value: Number(repeller3d.renderer.prop("radius"))
    }

    Support.Prop3dBinding {
        renderer: repeller3d.renderer
        target: repeller3d
        name: "outer_radius"
        property: "outerRadius"
        value: Number(repeller3d.renderer.prop("outer_radius"))
    }

    Support.Prop3dBinding {
        renderer: repeller3d.renderer
        target: repeller3d
        name: "strength"
        property: "strength"
        value: Number(repeller3d.renderer.prop("strength"))
    }

    Support.Prop3dBinding {
        renderer: repeller3d.renderer
        target: repeller3d
        name: "enabled"
        property: "enabled"
        value: repeller3d.renderer.prop("enabled") === true
    }
}
