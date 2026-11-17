import QtQuick
import QtQuick3D.Effects
import "Support" as Support

// Blurs whatever lies outside a focus range, measured in depth from the
// camera.
DepthOfFieldHQBlur {
    id: depthOfFieldHqBlur

    required property var renderer

    Support.Prop3dBinding {
        renderer: depthOfFieldHqBlur.renderer
        target: depthOfFieldHqBlur
        name: "focus_distance"
        property: "focusDistance"
        value: Number(depthOfFieldHqBlur.renderer.prop("focus_distance"))
    }

    Support.Prop3dBinding {
        renderer: depthOfFieldHqBlur.renderer
        target: depthOfFieldHqBlur
        name: "focus_range"
        property: "focusRange"
        value: Number(depthOfFieldHqBlur.renderer.prop("focus_range"))
    }

    Support.Prop3dBinding {
        renderer: depthOfFieldHqBlur.renderer
        target: depthOfFieldHqBlur
        name: "blur_amount"
        property: "blurAmount"
        value: Number(depthOfFieldHqBlur.renderer.prop("blur_amount"))
    }
}
