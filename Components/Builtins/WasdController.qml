import QtQuick
import QtQuick3D.Helpers
import "Support" as Support

// Moves a node with the W, A, S and D keys and turns it with the mouse,
// the usual way to walk through a scene while building it.
WasdController {
    id: wasdController

    required property var renderer

    controlledObject: renderer.sceneObject(renderer.prop("controlled_object", ""))

    Support.Prop3dBinding {
        renderer: wasdController.renderer
        target: wasdController
        name: "speed"
        property: "speed"
        value: Number(wasdController.renderer.prop("speed"))
    }

    Support.Prop3dBinding {
        renderer: wasdController.renderer
        target: wasdController
        name: "shift_speed"
        property: "shiftSpeed"
        value: Number(wasdController.renderer.prop("shift_speed"))
    }

    Support.Prop3dBinding {
        renderer: wasdController.renderer
        target: wasdController
        name: "forward_speed"
        property: "forwardSpeed"
        value: Number(wasdController.renderer.prop("forward_speed"))
    }

    Support.Prop3dBinding {
        renderer: wasdController.renderer
        target: wasdController
        name: "back_speed"
        property: "backSpeed"
        value: Number(wasdController.renderer.prop("back_speed"))
    }

    Support.Prop3dBinding {
        renderer: wasdController.renderer
        target: wasdController
        name: "right_speed"
        property: "rightSpeed"
        value: Number(wasdController.renderer.prop("right_speed"))
    }

    Support.Prop3dBinding {
        renderer: wasdController.renderer
        target: wasdController
        name: "left_speed"
        property: "leftSpeed"
        value: Number(wasdController.renderer.prop("left_speed"))
    }

    Support.Prop3dBinding {
        renderer: wasdController.renderer
        target: wasdController
        name: "up_speed"
        property: "upSpeed"
        value: Number(wasdController.renderer.prop("up_speed"))
    }

    Support.Prop3dBinding {
        renderer: wasdController.renderer
        target: wasdController
        name: "down_speed"
        property: "downSpeed"
        value: Number(wasdController.renderer.prop("down_speed"))
    }

    Support.Prop3dBinding {
        renderer: wasdController.renderer
        target: wasdController
        name: "x_speed"
        property: "xSpeed"
        value: Number(wasdController.renderer.prop("x_speed"))
    }

    Support.Prop3dBinding {
        renderer: wasdController.renderer
        target: wasdController
        name: "y_speed"
        property: "ySpeed"
        value: Number(wasdController.renderer.prop("y_speed"))
    }

    Support.Prop3dBinding {
        renderer: wasdController.renderer
        target: wasdController
        name: "x_invert"
        property: "xInvert"
        value: wasdController.renderer.prop("x_invert") === true
    }

    Support.Prop3dBinding {
        renderer: wasdController.renderer
        target: wasdController
        name: "y_invert"
        property: "yInvert"
        value: wasdController.renderer.prop("y_invert") === true
    }

    Support.Prop3dBinding {
        renderer: wasdController.renderer
        target: wasdController
        name: "mouse_enabled"
        property: "mouseEnabled"
        value: wasdController.renderer.prop("mouse_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: wasdController.renderer
        target: wasdController
        name: "keys_enabled"
        property: "keysEnabled"
        value: wasdController.renderer.prop("keys_enabled") === true
    }
}
