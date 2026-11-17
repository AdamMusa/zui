import QtQuick
import QtQuick3D.Particles3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// The volume an emitter spawns particles in: a cube, a sphere or a
// cylinder, either filled or only on its surface.
ParticleShape3D {
    id: particleShape3d

    required property var renderer

    property list<QtObject> propertyBindings: [
        Support.Prop3dBinding {
            renderer: particleShape3d.renderer
            target: particleShape3d
            name: "fill"
            property: "fill"
            value: particleShape3d.renderer.prop("fill") === true
        },
        Support.Prop3dBinding {
            renderer: particleShape3d.renderer
            target: particleShape3d
            name: "type"
            property: "type"
            value: Value3d.enumeration(particleShape3d.renderer.prop("type"), {
                "cube": ParticleShape3D.Cube,
                "sphere": ParticleShape3D.Sphere,
                "cylinder": ParticleShape3D.Cylinder
            }, ParticleShape3D.Cube)
        },
        Support.Prop3dBinding {
            renderer: particleShape3d.renderer
            target: particleShape3d
            name: "extents"
            property: "extents"
            value: Value3d.vector3d(particleShape3d.renderer.prop("extents"), 0, 0, 0)
        }
    ]
}
