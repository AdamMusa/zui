import QtQuick
import QtQuick3D.Effects
import "Support" as Support

// Keeps a band of the scene sharp and blurs the rest, the way a
// tilt-shift lens does.
TiltShift {
    id: tiltShift

    required property var renderer

    Support.Prop3dBinding {
        renderer: tiltShift.renderer
        target: tiltShift
        name: "focus_position"
        property: "focusPosition"
        value: Number(tiltShift.renderer.prop("focus_position"))
    }

    Support.Prop3dBinding {
        renderer: tiltShift.renderer
        target: tiltShift
        name: "focus_width"
        property: "focusWidth"
        value: Number(tiltShift.renderer.prop("focus_width"))
    }

    Support.Prop3dBinding {
        renderer: tiltShift.renderer
        target: tiltShift
        name: "blur_amount"
        property: "blurAmount"
        value: Number(tiltShift.renderer.prop("blur_amount"))
    }

    Support.Prop3dBinding {
        renderer: tiltShift.renderer
        target: tiltShift
        name: "is_vertical"
        property: "isVertical"
        value: tiltShift.renderer.prop("is_vertical") === true
    }

    Support.Prop3dBinding {
        renderer: tiltShift.renderer
        target: tiltShift
        name: "is_inverted"
        property: "isInverted"
        value: tiltShift.renderer.prop("is_inverted") === true
    }
}
