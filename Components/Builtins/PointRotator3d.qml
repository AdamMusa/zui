import QtQuick
import QtQuick3D.Particles3D
import "Support" as Support
import "Support/Value3d.js" as Value3d
import "Support/Scene3dTypes.js" as Scene3dTypes

// Spins particles around an axis through its position, for a vortex or
// a swirl.
PointRotator3D {
    id: pointRotator3d

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
        target: pointRotator3d
        property: "rotation"
        value: Value3d.quaternion(renderer.prop("rotation", null))
        when: renderer.hasProp("rotation")
        restoreMode: Binding.RestoreBindingOrValue
    }

    Support.Prop3dBinding {
        renderer: pointRotator3d.renderer
        target: pointRotator3d
        name: "magnitude"
        property: "magnitude"
        value: Number(pointRotator3d.renderer.prop("magnitude"))
    }

    Support.Prop3dBinding {
        renderer: pointRotator3d.renderer
        target: pointRotator3d
        name: "direction"
        property: "direction"
        value: Value3d.vector3d(pointRotator3d.renderer.prop("direction"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: pointRotator3d.renderer
        target: pointRotator3d
        name: "pivot_point"
        property: "pivotPoint"
        value: Value3d.vector3d(pointRotator3d.renderer.prop("pivot_point"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: pointRotator3d.renderer
        target: pointRotator3d
        name: "enabled"
        property: "enabled"
        value: pointRotator3d.renderer.prop("enabled") === true
    }
}
