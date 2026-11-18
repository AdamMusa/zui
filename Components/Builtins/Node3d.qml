import QtQuick
import QtQuick3D
import "Support/Value3d.js" as Value3d

// A transform in a Qt Quick 3D scene. Everything declared inside it moves,
// rotates and scales with it, which is how a Zui 3D scene is grouped.
Node {
    id: node3d

    required property var renderer

    position: Value3d.vector3d(renderer.prop("position", null), renderer.prop("x", 0),
                               renderer.prop("y", 0), renderer.prop("z", 0))
    eulerRotation: Value3d.vector3d(renderer.prop("euler_rotation", null),
                                    renderer.prop("rotation_x", 0),
                                    renderer.prop("rotation_y", 0),
                                    renderer.prop("rotation_z", 0))
    scale: Value3d.vector3d(renderer.prop("scale", null), 1, 1, 1)
    pivot: Value3d.vector3d(renderer.prop("pivot", null), 0, 0, 0)
    opacity: Number(renderer.prop("opacity", 1))
    visible: renderer.prop("visible", true) !== false
    staticFlags: Number(renderer.prop("static_flags", 0))

    // eulerRotation and rotation are two views of the same orientation, so the
    // quaternion is only applied when Ruby actually declared one.
    Binding {
        target: node3d
        property: "rotation"
        value: Value3d.quaternion(renderer.prop("rotation", null))
        when: renderer.hasProp("rotation")
        restoreMode: Binding.RestoreBindingOrValue
    }
}
