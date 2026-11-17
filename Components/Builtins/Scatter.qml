import QtQuick
import QtQuick3D.Effects
import "Support" as Support

// Scatters pixels along a noise texture, for frosted glass or
// interference.
Scatter {
    id: scatter

    required property var renderer

    Support.Prop3dBinding {
        renderer: scatter.renderer
        target: scatter
        name: "noise_sample"
        property: "noiseSample"
        value: scatter.renderer.sceneObject(scatter.renderer.prop("noise_sample"))
    }

    Support.Prop3dBinding {
        renderer: scatter.renderer
        target: scatter
        name: "amount"
        property: "amount"
        value: Number(scatter.renderer.prop("amount"))
    }

    Support.Prop3dBinding {
        renderer: scatter.renderer
        target: scatter
        name: "direction"
        property: "direction"
        value: Number(scatter.renderer.prop("direction"))
    }

    Support.Prop3dBinding {
        renderer: scatter.renderer
        target: scatter
        name: "randomize"
        property: "randomize"
        value: scatter.renderer.prop("randomize") === true
    }
}
