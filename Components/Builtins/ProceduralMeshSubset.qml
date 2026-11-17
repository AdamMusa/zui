import QtQuick
import QtQuick3D.Helpers
import "Support" as Support

// One named run of a procedural mesh's index array, so that part of the
// mesh can take a material of its own.
ProceduralMeshSubset {
    id: proceduralMeshSubset

    required property var renderer

    property list<QtObject> propertyBindings: [
        Support.Prop3dBinding {
            renderer: proceduralMeshSubset.renderer
            target: proceduralMeshSubset
            name: "offset"
            property: "offset"
            value: Number(proceduralMeshSubset.renderer.prop("offset"))
        },
        Support.Prop3dBinding {
            renderer: proceduralMeshSubset.renderer
            target: proceduralMeshSubset
            name: "count"
            property: "count"
            value: Number(proceduralMeshSubset.renderer.prop("count"))
        },
        Support.Prop3dBinding {
            renderer: proceduralMeshSubset.renderer
            target: proceduralMeshSubset
            name: "name"
            property: "name"
            value: String(proceduralMeshSubset.renderer.prop("name"))
        }
    ]
}
