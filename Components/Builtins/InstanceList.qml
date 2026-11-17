import QtQuick
import QtQuick3D
import "Support" as Support

// Draws one mesh many times in a single pass, with a per-instance
// transform, colour and custom data. The instances are the
// instance_list_entry nodes declared inside the list.
InstanceList {
    id: instanceList

    required property var renderer

    instances: renderer.childObjectsAndReferences(["instance_list_entry"], "instances")

    property list<QtObject> propertyBindings: [
        Support.Prop3dBinding {
            renderer: instanceList.renderer
            target: instanceList
            name: "instance_count_override"
            property: "instanceCountOverride"
            value: Number(instanceList.renderer.prop("instance_count_override"))
        },
        Support.Prop3dBinding {
            renderer: instanceList.renderer
            target: instanceList
            name: "has_transparency"
            property: "hasTransparency"
            value: instanceList.renderer.prop("has_transparency") === true
        },
        Support.Prop3dBinding {
            renderer: instanceList.renderer
            target: instanceList
            name: "depth_sorting_enabled"
            property: "depthSortingEnabled"
            value: instanceList.renderer.prop("depth_sorting_enabled") === true
        }
    ]
}
