import QtQuick
import QtQuick3D.Particles3D
import "Support" as Support

// A burst of particles at a fixed time on the system's clock, for a
// single puff or explosion.
EmitBurst3D {
    id: emitBurst3d

    required property var renderer

    property list<QtObject> propertyBindings: [
        Support.Prop3dBinding {
            renderer: emitBurst3d.renderer
            target: emitBurst3d
            name: "time"
            property: "time"
            value: Number(emitBurst3d.renderer.prop("time"))
        },
        Support.Prop3dBinding {
            renderer: emitBurst3d.renderer
            target: emitBurst3d
            name: "amount"
            property: "amount"
            value: Number(emitBurst3d.renderer.prop("amount"))
        },
        Support.Prop3dBinding {
            renderer: emitBurst3d.renderer
            target: emitBurst3d
            name: "duration"
            property: "duration"
            value: Number(emitBurst3d.renderer.prop("duration"))
        }
    ]
}
