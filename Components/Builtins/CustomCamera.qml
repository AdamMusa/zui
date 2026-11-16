import QtQuick
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// A camera driven by an explicit 4x4 projection matrix, for a
// projection none of the other cameras can describe.
CustomCamera {
    id: customCamera

    required property var renderer

    position: Value3d.vector3d(renderer.prop("position", null), renderer.prop("x", 0), renderer.prop("y", 0), renderer.prop("z", 0))
    eulerRotation: Value3d.vector3d(renderer.prop("euler_rotation", null), renderer.prop("rotation_x", 0), renderer.prop("rotation_y", 0), renderer.prop("rotation_z", 0))
    scale: Value3d.vector3d(renderer.prop("scale", null), 1, 1, 1)
    pivot: Value3d.vector3d(renderer.prop("pivot", null), 0, 0, 0)
    opacity: Number(renderer.prop("opacity", 1))
    visible: renderer.prop("visible", true) !== false
    staticFlags: Number(renderer.prop("static_flags", 0))
    lookAtNode: renderer.sceneObject(renderer.prop("look_at", ""))

    // eulerRotation and rotation describe the same orientation, so the
    // quaternion is applied only when Ruby declared one.
    Binding {
        target: customCamera
        property: "rotation"
        value: Value3d.quaternion(renderer.prop("rotation", null))
        when: renderer.hasProp("rotation")
        restoreMode: Binding.RestoreBindingOrValue
    }

    Support.Prop3dBinding {
        renderer: customCamera.renderer
        target: customCamera
        name: "projection"
        property: "projection"
        value: Value3d.matrix4x4(customCamera.renderer.prop("projection"))
    }

    Support.Prop3dBinding {
        renderer: customCamera.renderer
        target: customCamera
        name: "frustum_culling"
        property: "frustumCullingEnabled"
        value: customCamera.renderer.prop("frustum_culling") === true
    }

    Support.Prop3dBinding {
        renderer: customCamera.renderer
        target: customCamera
        name: "level_of_detail_bias"
        property: "levelOfDetailBias"
        value: Number(customCamera.renderer.prop("level_of_detail_bias"))
    }
}
