import QtQuick
import QtQuick3D.Effects
import "Support" as Support
import "Support/Value3d.js" as Value3d

// Bends the image as though seen through a glass sphere.
DistortionSphere {
    id: distortionSphere

    required property var renderer

    Support.Prop3dBinding {
        renderer: distortionSphere.renderer
        target: distortionSphere
        name: "radius"
        property: "radius"
        value: Number(distortionSphere.renderer.prop("radius"))
    }

    Support.Prop3dBinding {
        renderer: distortionSphere.renderer
        target: distortionSphere
        name: "distortion_height"
        property: "distortionHeight"
        value: Number(distortionSphere.renderer.prop("distortion_height"))
    }

    Support.Prop3dBinding {
        renderer: distortionSphere.renderer
        target: distortionSphere
        name: "center"
        property: "center"
        value: Value3d.vector2d(distortionSphere.renderer.prop("center"), 0, 0)
    }
}
