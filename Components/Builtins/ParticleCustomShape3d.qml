import QtQuick
import QtQuick3D.Particles3D
import "Support" as Support

// Spawns particles at positions baked into a .cbor shape file, for a
// distribution authored outside the application.
ParticleCustomShape3D {
    id: particleCustomShape3d

    required property var renderer

    property list<QtObject> propertyBindings: [
        Support.Prop3dBinding {
            renderer: particleCustomShape3d.renderer
            target: particleCustomShape3d
            name: "source"
            property: "source"
            value: particleCustomShape3d.renderer.assetUrl(particleCustomShape3d.renderer.prop("source"))
        },
        Support.Prop3dBinding {
            renderer: particleCustomShape3d.renderer
            target: particleCustomShape3d
            name: "randomize_data"
            property: "randomizeData"
            value: particleCustomShape3d.renderer.prop("randomize_data") === true
        }
    ]
}
