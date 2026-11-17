import QtQuick
import QtQuick3D.Effects
import "Support" as Support

// Pulls the colour out of the scene, down to grey.
Desaturate {
    id: desaturate3d

    required property var renderer

    Support.Prop3dBinding {
        renderer: desaturate3d.renderer
        target: desaturate3d
        name: "amount"
        property: "amount"
        value: Number(desaturate3d.renderer.prop("amount"))
    }
}
