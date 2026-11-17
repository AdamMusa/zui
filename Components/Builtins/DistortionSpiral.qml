import QtQuick
import QtQuick3D.Effects
import "Support" as Support
import "Support/Value3d.js" as Value3d

// Twists the image around a point.
DistortionSpiral {
    id: distortionSpiral

    required property var renderer

    Support.Prop3dBinding {
        renderer: distortionSpiral.renderer
        target: distortionSpiral
        name: "radius"
        property: "radius"
        value: Number(distortionSpiral.renderer.prop("radius"))
    }

    Support.Prop3dBinding {
        renderer: distortionSpiral.renderer
        target: distortionSpiral
        name: "distortion_strength"
        property: "distortionStrength"
        value: Number(distortionSpiral.renderer.prop("distortion_strength"))
    }

    Support.Prop3dBinding {
        renderer: distortionSpiral.renderer
        target: distortionSpiral
        name: "center"
        property: "center"
        value: Value3d.vector2d(distortionSpiral.renderer.prop("center"), 0, 0)
    }
}
