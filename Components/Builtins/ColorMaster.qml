import QtQuick
import QtQuick3D.Effects
import "Support" as Support

// Per-channel gain plus saturation, for grading the whole scene.
ColorMaster {
    id: colorMaster

    required property var renderer

    Support.Prop3dBinding {
        renderer: colorMaster.renderer
        target: colorMaster
        name: "red_strength"
        property: "redStrength"
        value: Number(colorMaster.renderer.prop("red_strength"))
    }

    Support.Prop3dBinding {
        renderer: colorMaster.renderer
        target: colorMaster
        name: "green_strength"
        property: "greenStrength"
        value: Number(colorMaster.renderer.prop("green_strength"))
    }

    Support.Prop3dBinding {
        renderer: colorMaster.renderer
        target: colorMaster
        name: "blue_strength"
        property: "blueStrength"
        value: Number(colorMaster.renderer.prop("blue_strength"))
    }

    Support.Prop3dBinding {
        renderer: colorMaster.renderer
        target: colorMaster
        name: "saturation"
        property: "saturation"
        value: Number(colorMaster.renderer.prop("saturation"))
    }
}
