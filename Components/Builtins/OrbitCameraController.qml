import QtQuick
import QtQuick3D.Helpers
import "Support" as Support

// Turns a camera around a node by dragging, and zooms with the wheel or
// a pinch. The controller is a Qt Quick item, so it sits over the
// viewport rather than in the scene; declare it inside the view_3d whose
// camera it drives.
OrbitCameraController {
    id: orbitCameraController

    required property var renderer

    origin: renderer.sceneObject(renderer.prop("origin", ""))
    camera: renderer.sceneObject(renderer.prop("camera", ""))

    Support.Prop3dBinding {
        renderer: orbitCameraController.renderer
        target: orbitCameraController
        name: "x_speed"
        property: "xSpeed"
        value: Number(orbitCameraController.renderer.prop("x_speed"))
    }

    Support.Prop3dBinding {
        renderer: orbitCameraController.renderer
        target: orbitCameraController
        name: "y_speed"
        property: "ySpeed"
        value: Number(orbitCameraController.renderer.prop("y_speed"))
    }

    Support.Prop3dBinding {
        renderer: orbitCameraController.renderer
        target: orbitCameraController
        name: "x_invert"
        property: "xInvert"
        value: orbitCameraController.renderer.prop("x_invert") === true
    }

    Support.Prop3dBinding {
        renderer: orbitCameraController.renderer
        target: orbitCameraController
        name: "y_invert"
        property: "yInvert"
        value: orbitCameraController.renderer.prop("y_invert") === true
    }

    Support.Prop3dBinding {
        renderer: orbitCameraController.renderer
        target: orbitCameraController
        name: "mouse_enabled"
        property: "mouseEnabled"
        value: orbitCameraController.renderer.prop("mouse_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: orbitCameraController.renderer
        target: orbitCameraController
        name: "pan_enabled"
        property: "panEnabled"
        value: orbitCameraController.renderer.prop("pan_enabled") === true
    }
}
