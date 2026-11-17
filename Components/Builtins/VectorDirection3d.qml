import QtQuick
import QtQuick3D.Particles3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// Sends particles along one direction, with a declared spread.
VectorDirection3D {
    id: vectorDirection3d

    required property var renderer

    property list<QtObject> propertyBindings: [
        Support.Prop3dBinding {
            renderer: vectorDirection3d.renderer
            target: vectorDirection3d
            name: "direction"
            property: "direction"
            value: Value3d.vector3d(vectorDirection3d.renderer.prop("direction"), 0, 0, 0)
        },
        Support.Prop3dBinding {
            renderer: vectorDirection3d.renderer
            target: vectorDirection3d
            name: "direction_variation"
            property: "directionVariation"
            value: Value3d.vector3d(vectorDirection3d.renderer.prop("direction_variation"), 0, 0, 0)
        },
        Support.Prop3dBinding {
            renderer: vectorDirection3d.renderer
            target: vectorDirection3d
            name: "normalized"
            property: "normalized"
            value: vectorDirection3d.renderer.prop("normalized") === true
        }
    ]
}
