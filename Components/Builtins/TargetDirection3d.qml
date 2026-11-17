import QtQuick
import QtQuick3D.Particles3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// Sends particles towards a point, with a declared spread and speed.
TargetDirection3D {
    id: targetDirection3d

    required property var renderer

    property list<QtObject> propertyBindings: [
        Support.Prop3dBinding {
            renderer: targetDirection3d.renderer
            target: targetDirection3d
            name: "position"
            property: "position"
            value: Value3d.vector3d(targetDirection3d.renderer.prop("position"), 0, 0, 0)
        },
        Support.Prop3dBinding {
            renderer: targetDirection3d.renderer
            target: targetDirection3d
            name: "position_variation"
            property: "positionVariation"
            value: Value3d.vector3d(targetDirection3d.renderer.prop("position_variation"), 0, 0, 0)
        },
        Support.Prop3dBinding {
            renderer: targetDirection3d.renderer
            target: targetDirection3d
            name: "normalized"
            property: "normalized"
            value: targetDirection3d.renderer.prop("normalized") === true
        },
        Support.Prop3dBinding {
            renderer: targetDirection3d.renderer
            target: targetDirection3d
            name: "magnitude"
            property: "magnitude"
            value: Number(targetDirection3d.renderer.prop("magnitude"))
        },
        Support.Prop3dBinding {
            renderer: targetDirection3d.renderer
            target: targetDirection3d
            name: "magnitude_variation"
            property: "magnitudeVariation"
            value: Number(targetDirection3d.renderer.prop("magnitude_variation"))
        }
    ]
}
