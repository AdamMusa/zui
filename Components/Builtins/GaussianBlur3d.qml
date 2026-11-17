import QtQuick
import QtQuick3D.Effects
import "Support" as Support

// A true Gaussian blur of the whole scene.
GaussianBlur {
    id: gaussianBlur3d

    required property var renderer

    Support.Prop3dBinding {
        renderer: gaussianBlur3d.renderer
        target: gaussianBlur3d
        name: "amount"
        property: "amount"
        value: Number(gaussianBlur3d.renderer.prop("amount"))
    }
}
