import QtQuick
import QtQuick3D.Helpers
import "Support" as Support
import "Support/Value3d.js" as Value3d

// The bounds random_instancing draws one of its values from. A bound is
// a number for a scalar and [x, y, z] for a position, scale or rotation,
// and proportional ties the components together instead of varying them
// independently.
InstanceRange {
    id: instanceRange

    required property var renderer

    property list<QtObject> propertyBindings: [
        Support.Prop3dBinding {
            renderer: instanceRange.renderer
            target: instanceRange
            name: "from"
            property: "from"
            value: Value3d.rangeValue(instanceRange.renderer.prop("from"))
        },
        Support.Prop3dBinding {
            renderer: instanceRange.renderer
            target: instanceRange
            name: "proportional"
            property: "proportional"
            value: instanceRange.renderer.prop("proportional") === true
        },
        Support.Prop3dBinding {
            renderer: instanceRange.renderer
            target: instanceRange
            name: "to"
            property: "to"
            value: Value3d.rangeValue(instanceRange.renderer.prop("to"))
        }
    ]
}
