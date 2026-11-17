import QtQuick
import QtQuick3D.Particles3D
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d
import "Support/Scene3dTypes.js" as Scene3dTypes

// Spawns particles over the surface or through the volume of a mesh, so
// a shape of your own decides where they appear.
ParticleModelShape3D {
    id: particleModelShape3d

    required property var renderer

    // Qt takes the per-particle model as a Component, so the mesh and
    // materials are declared here the way model_3d declares them.
    delegate: Component {
        Model {
            source: Value3d.meshSource(particleModelShape3d.renderer, particleModelShape3d.renderer.prop("source", "#Sphere"))
            materials: particleModelShape3d.renderer.childObjectsAndReferences(Scene3dTypes.materials, "materials")
            geometry: particleModelShape3d.renderer.childObjectOrReference(Scene3dTypes.geometries, "geometry")
        }
    }

    property list<QtObject> propertyBindings: [
        Support.Prop3dBinding {
            renderer: particleModelShape3d.renderer
            target: particleModelShape3d
            name: "fill"
            property: "fill"
            value: particleModelShape3d.renderer.prop("fill") === true
        }
    ]
}
