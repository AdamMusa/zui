import QtQuick
import QtQuick3D.Effects
import "Support" as Support
import "Support/Value3d.js" as Value3d

// Darkens the scene towards the corners.
Vignette {
    id: vignette3d

    required property var renderer

    Support.Prop3dBinding {
        renderer: vignette3d.renderer
        target: vignette3d
        name: "vignette_strength"
        property: "vignetteStrength"
        value: Number(vignette3d.renderer.prop("vignette_strength"))
    }

    Support.Prop3dBinding {
        renderer: vignette3d.renderer
        target: vignette3d
        name: "vignette_color"
        property: "vignetteColor"
        value: Value3d.vector3d(vignette3d.renderer.prop("vignette_color"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: vignette3d.renderer
        target: vignette3d
        name: "vignette_radius"
        property: "vignetteRadius"
        value: Number(vignette3d.renderer.prop("vignette_radius"))
    }
}
