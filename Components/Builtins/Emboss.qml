import QtQuick
import QtQuick3D.Effects
import "Support" as Support

// Turns differences in brightness into a raised relief.
Emboss {
    id: emboss

    required property var renderer

    Support.Prop3dBinding {
        renderer: emboss.renderer
        target: emboss
        name: "amount"
        property: "amount"
        value: Number(emboss.renderer.prop("amount"))
    }
}
