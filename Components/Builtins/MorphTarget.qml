import QtQuick
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// One shape a mesh can be blended towards, weighted from 0 to 1.
// attributes names which vertex channels the target carries, and can be
// given several at once.
MorphTarget {
    id: morphTarget

    required property var renderer

    Support.Prop3dBinding {
        renderer: morphTarget.renderer
        target: morphTarget
        name: "weight"
        property: "weight"
        value: Number(morphTarget.renderer.prop("weight"))
    }

    Support.Prop3dBinding {
        renderer: morphTarget.renderer
        target: morphTarget
        name: "attributes"
        property: "attributes"
        value: Value3d.flags(morphTarget.renderer.prop("attributes"), {
            "position": MorphTarget.Position,
            "normal": MorphTarget.Normal,
            "tangent": MorphTarget.Tangent,
            "binormal": MorphTarget.Binormal,
            "tex_coord0": MorphTarget.TexCoord0,
            "tex_coord1": MorphTarget.TexCoord1,
            "color": MorphTarget.Color
        }, MorphTarget.Position)
    }
}
