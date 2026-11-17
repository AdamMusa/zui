import QtQuick
import QtQuick3D.Effects
import "Support" as Support
import "Support/Value3d.js" as Value3d

// Adds a vertical colour gradient over the scene, which is the cheapest
// way to tint a sky or ground.
AdditiveColorGradient {
    id: additiveColorGradient

    required property var renderer

    Support.Prop3dBinding {
        renderer: additiveColorGradient.renderer
        target: additiveColorGradient
        name: "bottom_color"
        property: "bottomColor"
        value: Value3d.vector3d(additiveColorGradient.renderer.prop("bottom_color"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: additiveColorGradient.renderer
        target: additiveColorGradient
        name: "top_color"
        property: "topColor"
        value: Value3d.vector3d(additiveColorGradient.renderer.prop("top_color"), 0, 0, 0)
    }
}
