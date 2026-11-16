import QtQuick
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// A camera with a parallel projection: geometry keeps its size whatever
// its distance, which suits plans, diagrams and isometric scenes.
OrthographicCamera {
    id: orthographicCamera

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
        target: orthographicCamera
        property: "rotation"
        value: Value3d.quaternion(renderer.prop("rotation", null))
        when: renderer.hasProp("rotation")
        restoreMode: Binding.RestoreBindingOrValue
    }

    Support.Prop3dBinding {
        renderer: orthographicCamera.renderer
        target: orthographicCamera
        name: "clip_near"
        property: "clipNear"
        value: Number(orthographicCamera.renderer.prop("clip_near"))
    }

    Support.Prop3dBinding {
        renderer: orthographicCamera.renderer
        target: orthographicCamera
        name: "clip_far"
        property: "clipFar"
        value: Number(orthographicCamera.renderer.prop("clip_far"))
    }

    Support.Prop3dBinding {
        renderer: orthographicCamera.renderer
        target: orthographicCamera
        name: "horizontal_magnification"
        property: "horizontalMagnification"
        value: Number(orthographicCamera.renderer.prop("horizontal_magnification"))
    }

    Support.Prop3dBinding {
        renderer: orthographicCamera.renderer
        target: orthographicCamera
        name: "vertical_magnification"
        property: "verticalMagnification"
        value: Number(orthographicCamera.renderer.prop("vertical_magnification"))
    }

    Support.Prop3dBinding {
        renderer: orthographicCamera.renderer
        target: orthographicCamera
        name: "frustum_culling"
        property: "frustumCullingEnabled"
        value: orthographicCamera.renderer.prop("frustum_culling") === true
    }

    Support.Prop3dBinding {
        renderer: orthographicCamera.renderer
        target: orthographicCamera
        name: "level_of_detail_bias"
        property: "levelOfDetailBias"
        value: Number(orthographicCamera.renderer.prop("level_of_detail_bias"))
    }
}
