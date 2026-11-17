import QtQuick
import QtQuick3D.Effects
import "Support" as Support

// A light blur of the whole scene.
Blur {
    id: blur3d

    required property var renderer

    Support.Prop3dBinding {
        renderer: blur3d.renderer
        target: blur3d
        name: "amount"
        property: "amount"
        value: Number(blur3d.renderer.prop("amount"))
    }
}
