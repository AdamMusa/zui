import QtQuick
import QtQuick3D.Effects
import "Support" as Support

// Separates the colour channels towards the edges, the way a real lens
// does.
ChromaticAberration {
    id: chromaticAberration

    required property var renderer

    Support.Prop3dBinding {
        renderer: chromaticAberration.renderer
        target: chromaticAberration
        name: "mask_texture"
        property: "maskTexture"
        value: chromaticAberration.renderer.sceneObject(chromaticAberration.renderer.prop("mask_texture"))
    }

    Support.Prop3dBinding {
        renderer: chromaticAberration.renderer
        target: chromaticAberration
        name: "aberration_amount"
        property: "aberrationAmount"
        value: Number(chromaticAberration.renderer.prop("aberration_amount"))
    }

    Support.Prop3dBinding {
        renderer: chromaticAberration.renderer
        target: chromaticAberration
        name: "focus_depth"
        property: "focusDepth"
        value: Number(chromaticAberration.renderer.prop("focus_depth"))
    }
}
