import QtQuick
import QtQuick3D.Effects
import "Support" as Support
import "Support/Value3d.js" as Value3d

// Bends the image in rings spreading from a point.
DistortionRipple {
    id: distortionRipple

    required property var renderer

    Support.Prop3dBinding {
        renderer: distortionRipple.renderer
        target: distortionRipple
        name: "radius"
        property: "radius"
        value: Number(distortionRipple.renderer.prop("radius"))
    }

    Support.Prop3dBinding {
        renderer: distortionRipple.renderer
        target: distortionRipple
        name: "distortion_width"
        property: "distortionWidth"
        value: Number(distortionRipple.renderer.prop("distortion_width"))
    }

    Support.Prop3dBinding {
        renderer: distortionRipple.renderer
        target: distortionRipple
        name: "distortion_height"
        property: "distortionHeight"
        value: Number(distortionRipple.renderer.prop("distortion_height"))
    }

    Support.Prop3dBinding {
        renderer: distortionRipple.renderer
        target: distortionRipple
        name: "distortion_phase"
        property: "distortionPhase"
        value: Number(distortionRipple.renderer.prop("distortion_phase"))
    }

    Support.Prop3dBinding {
        renderer: distortionRipple.renderer
        target: distortionRipple
        name: "center"
        property: "center"
        value: Value3d.vector2d(distortionRipple.renderer.prop("center"), 0, 0)
    }
}
