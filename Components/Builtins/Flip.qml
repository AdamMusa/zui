import QtQuick
import QtQuick3D.Effects
import "Support" as Support

// Mirrors the scene horizontally, vertically or both.
Flip {
    id: flip

    required property var renderer

    Support.Prop3dBinding {
        renderer: flip.renderer
        target: flip
        name: "flip_horizontally"
        property: "flipHorizontally"
        value: flip.renderer.prop("flip_horizontally") === true
    }

    Support.Prop3dBinding {
        renderer: flip.renderer
        target: flip
        name: "flip_vertically"
        property: "flipVertically"
        value: flip.renderer.prop("flip_vertically") === true
    }
}
