import QtQuick
import QtQuick3D.Particles3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// A burst triggered by a particle's own start or end rather than by the
// clock, which is how one particle's death becomes another's birth.
DynamicBurst3D {
    id: dynamicBurst3d

    required property var renderer

    property list<QtObject> propertyBindings: [
        Support.Prop3dBinding {
            renderer: dynamicBurst3d.renderer
            target: dynamicBurst3d
            name: "enabled"
            property: "enabled"
            value: dynamicBurst3d.renderer.prop("enabled") === true
        },
        Support.Prop3dBinding {
            renderer: dynamicBurst3d.renderer
            target: dynamicBurst3d
            name: "amount_variation"
            property: "amountVariation"
            value: Number(dynamicBurst3d.renderer.prop("amount_variation"))
        },
        Support.Prop3dBinding {
            renderer: dynamicBurst3d.renderer
            target: dynamicBurst3d
            name: "trigger_mode"
            property: "triggerMode"
            value: Value3d.enumeration(dynamicBurst3d.renderer.prop("trigger_mode"), {
                "time": DynamicBurst3D.TriggerTime,
                "start": DynamicBurst3D.TriggerStart,
                "end": DynamicBurst3D.TriggerEnd
            }, DynamicBurst3D.TriggerTime)
        },
        Support.Prop3dBinding {
            renderer: dynamicBurst3d.renderer
            target: dynamicBurst3d
            name: "time"
            property: "time"
            value: Number(dynamicBurst3d.renderer.prop("time"))
        },
        Support.Prop3dBinding {
            renderer: dynamicBurst3d.renderer
            target: dynamicBurst3d
            name: "amount"
            property: "amount"
            value: Number(dynamicBurst3d.renderer.prop("amount"))
        },
        Support.Prop3dBinding {
            renderer: dynamicBurst3d.renderer
            target: dynamicBurst3d
            name: "duration"
            property: "duration"
            value: Number(dynamicBurst3d.renderer.prop("duration"))
        }
    ]
}
