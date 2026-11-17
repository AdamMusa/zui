import QtQuick
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// One instance of an instance_list: where it sits, how it is turned and
// scaled, its colour, and four custom floats a shader can read.
InstanceListEntry {
    id: instanceListEntry

    required property var renderer

    Support.Prop3dBinding {
        renderer: instanceListEntry.renderer
        target: instanceListEntry
        name: "position"
        property: "position"
        value: Value3d.vector3d(instanceListEntry.renderer.prop("position"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: instanceListEntry.renderer
        target: instanceListEntry
        name: "scale"
        property: "scale"
        value: Value3d.vector3d(instanceListEntry.renderer.prop("scale"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: instanceListEntry.renderer
        target: instanceListEntry
        name: "euler_rotation"
        property: "eulerRotation"
        value: Value3d.vector3d(instanceListEntry.renderer.prop("euler_rotation"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: instanceListEntry.renderer
        target: instanceListEntry
        name: "rotation"
        property: "rotation"
        value: Value3d.quaternion(instanceListEntry.renderer.prop("rotation"))
    }

    Support.Prop3dBinding {
        renderer: instanceListEntry.renderer
        target: instanceListEntry
        name: "color"
        property: "color"
        value: instanceListEntry.renderer.prop("color")
    }

    Support.Prop3dBinding {
        renderer: instanceListEntry.renderer
        target: instanceListEntry
        name: "custom_data"
        property: "customData"
        value: Value3d.vector4d(instanceListEntry.renderer.prop("custom_data"), 0, 0, 0, 0)
    }
}
