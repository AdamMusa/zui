import QtQuick
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// A camera with a perspective projection: distant geometry looks smaller,
// which is how a scene is normally viewed. A view_3d adopts the first
// camera declared inside it, and look_at names a node to keep framed.
PerspectiveCamera {
    id: perspectiveCamera

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
        target: perspectiveCamera
        property: "rotation"
        value: Value3d.quaternion(renderer.prop("rotation", null))
        when: renderer.hasProp("rotation")
        restoreMode: Binding.RestoreBindingOrValue
    }

    Support.Prop3dBinding {
        renderer: perspectiveCamera.renderer
        target: perspectiveCamera
        name: "clip_near"
        property: "clipNear"
        value: Number(perspectiveCamera.renderer.prop("clip_near"))
    }

    Support.Prop3dBinding {
        renderer: perspectiveCamera.renderer
        target: perspectiveCamera
        name: "clip_far"
        property: "clipFar"
        value: Number(perspectiveCamera.renderer.prop("clip_far"))
    }

    Support.Prop3dBinding {
        renderer: perspectiveCamera.renderer
        target: perspectiveCamera
        name: "field_of_view"
        property: "fieldOfView"
        value: Number(perspectiveCamera.renderer.prop("field_of_view"))
    }

    Support.Prop3dBinding {
        renderer: perspectiveCamera.renderer
        target: perspectiveCamera
        name: "field_of_view_orientation"
        property: "fieldOfViewOrientation"
        value: Value3d.enumeration(perspectiveCamera.renderer.prop("field_of_view_orientation"), {
            "vertical": PerspectiveCamera.Vertical,
            "horizontal": PerspectiveCamera.Horizontal
        }, PerspectiveCamera.Vertical)
    }

    Support.Prop3dBinding {
        renderer: perspectiveCamera.renderer
        target: perspectiveCamera
        name: "frustum_culling"
        property: "frustumCullingEnabled"
        value: perspectiveCamera.renderer.prop("frustum_culling") === true
    }

    Support.Prop3dBinding {
        renderer: perspectiveCamera.renderer
        target: perspectiveCamera
        name: "level_of_detail_bias"
        property: "levelOfDetailBias"
        value: Number(perspectiveCamera.renderer.prop("level_of_detail_bias"))
    }
}
