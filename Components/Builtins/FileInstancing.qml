import QtQuick
import QtQuick3D
import "Support" as Support

// Instances loaded from a binary instance table on disk, for a field too
// large to declare node by node.
FileInstancing {
    id: fileInstancing

    required property var renderer

    Support.Prop3dBinding {
        renderer: fileInstancing.renderer
        target: fileInstancing
        name: "source"
        property: "source"
        value: fileInstancing.renderer.assetUrl(fileInstancing.renderer.prop("source"))
    }

    Support.Prop3dBinding {
        renderer: fileInstancing.renderer
        target: fileInstancing
        name: "instance_count_override"
        property: "instanceCountOverride"
        value: Number(fileInstancing.renderer.prop("instance_count_override"))
    }

    Support.Prop3dBinding {
        renderer: fileInstancing.renderer
        target: fileInstancing
        name: "has_transparency"
        property: "hasTransparency"
        value: fileInstancing.renderer.prop("has_transparency") === true
    }

    Support.Prop3dBinding {
        renderer: fileInstancing.renderer
        target: fileInstancing
        name: "depth_sorting_enabled"
        property: "depthSortingEnabled"
        value: fileInstancing.renderer.prop("depth_sorting_enabled") === true
    }
}
