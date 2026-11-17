import QtQuick
import QtQuick3D.Effects
import "Support" as Support

// Smears the scene along the motion between frames.
MotionBlur {
    id: motionBlur

    required property var renderer

    Support.Prop3dBinding {
        renderer: motionBlur.renderer
        target: motionBlur
        name: "fade_amount"
        property: "fadeAmount"
        value: Number(motionBlur.renderer.prop("fade_amount"))
    }

    Support.Prop3dBinding {
        renderer: motionBlur.renderer
        target: motionBlur
        name: "blur_quality"
        property: "blurQuality"
        value: Number(motionBlur.renderer.prop("blur_quality"))
    }
}
