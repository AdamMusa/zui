import QtQuick
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// A perspective camera whose view frustum is given by its four side
// planes instead of a field of view, for an asymmetric or off-centre
// projection such as one half of a stereo pair.
FrustumCamera {
    id: frustumCamera

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
        target: frustumCamera
        property: "rotation"
        value: Value3d.quaternion(renderer.prop("rotation", null))
        when: renderer.hasProp("rotation")
        restoreMode: Binding.RestoreBindingOrValue
    }

    Support.Prop3dBinding {
        renderer: frustumCamera.renderer
        target: frustumCamera
        name: "bottom"
        property: "bottom"
        value: Number(frustumCamera.renderer.prop("bottom"))
    }

    Support.Prop3dBinding {
        renderer: frustumCamera.renderer
        target: frustumCamera
        name: "right"
        property: "right"
        value: Number(frustumCamera.renderer.prop("right"))
    }

    Support.Prop3dBinding {
        renderer: frustumCamera.renderer
        target: frustumCamera
        name: "left"
        property: "left"
        value: Number(frustumCamera.renderer.prop("left"))
    }

    Support.Prop3dBinding {
        renderer: frustumCamera.renderer
        target: frustumCamera
        name: "top"
        property: "top"
        value: Number(frustumCamera.renderer.prop("top"))
    }

    Support.Prop3dBinding {
        renderer: frustumCamera.renderer
        target: frustumCamera
        name: "clip_near"
        property: "clipNear"
        value: Number(frustumCamera.renderer.prop("clip_near"))
    }

    Support.Prop3dBinding {
        renderer: frustumCamera.renderer
        target: frustumCamera
        name: "clip_far"
        property: "clipFar"
        value: Number(frustumCamera.renderer.prop("clip_far"))
    }

    Support.Prop3dBinding {
        renderer: frustumCamera.renderer
        target: frustumCamera
        name: "field_of_view"
        property: "fieldOfView"
        value: Number(frustumCamera.renderer.prop("field_of_view"))
    }

    Support.Prop3dBinding {
        renderer: frustumCamera.renderer
        target: frustumCamera
        name: "field_of_view_orientation"
        property: "fieldOfViewOrientation"
        value: Value3d.enumeration(frustumCamera.renderer.prop("field_of_view_orientation"), {
            "vertical": FrustumCamera.Vertical,
            "horizontal": FrustumCamera.Horizontal
        }, FrustumCamera.Vertical)
    }

    Support.Prop3dBinding {
        renderer: frustumCamera.renderer
        target: frustumCamera
        name: "frustum_culling"
        property: "frustumCullingEnabled"
        value: frustumCamera.renderer.prop("frustum_culling") === true
    }

    Support.Prop3dBinding {
        renderer: frustumCamera.renderer
        target: frustumCamera
        name: "level_of_detail_bias"
        property: "levelOfDetailBias"
        value: Number(frustumCamera.renderer.prop("level_of_detail_bias"))
    }
}
