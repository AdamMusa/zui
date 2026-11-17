import QtQuick
import QtQuick3D.Effects
import "Support" as Support

// Keeps only the edges in the scene, for a line-drawn look.
EdgeDetect {
    id: edgeDetect

    required property var renderer

    Support.Prop3dBinding {
        renderer: edgeDetect.renderer
        target: edgeDetect
        name: "edge_strength"
        property: "edgeStrength"
        value: Number(edgeDetect.renderer.prop("edge_strength"))
    }
}
