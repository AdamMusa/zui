import QtQuick
import QtQuick3D
import "Support" as Support

// Atmospheric fog for a scene environment. Depth fog thickens with
// distance, height fog fills a slab of the scene, and transmission lets
// light through it.
Fog {
    id: fog3d

    required property var renderer

    property list<QtObject> propertyBindings: [
        Support.Prop3dBinding {
            renderer: fog3d.renderer
            target: fog3d
            name: "enabled"
            property: "enabled"
            value: fog3d.renderer.prop("enabled") === true
        },
        Support.Prop3dBinding {
            renderer: fog3d.renderer
            target: fog3d
            name: "color"
            property: "color"
            value: fog3d.renderer.prop("color")
        },
        Support.Prop3dBinding {
            renderer: fog3d.renderer
            target: fog3d
            name: "density"
            property: "density"
            value: Number(fog3d.renderer.prop("density"))
        },
        Support.Prop3dBinding {
            renderer: fog3d.renderer
            target: fog3d
            name: "depth_enabled"
            property: "depthEnabled"
            value: fog3d.renderer.prop("depth_enabled") === true
        },
        Support.Prop3dBinding {
            renderer: fog3d.renderer
            target: fog3d
            name: "depth_near"
            property: "depthNear"
            value: Number(fog3d.renderer.prop("depth_near"))
        },
        Support.Prop3dBinding {
            renderer: fog3d.renderer
            target: fog3d
            name: "depth_far"
            property: "depthFar"
            value: Number(fog3d.renderer.prop("depth_far"))
        },
        Support.Prop3dBinding {
            renderer: fog3d.renderer
            target: fog3d
            name: "depth_curve"
            property: "depthCurve"
            value: Number(fog3d.renderer.prop("depth_curve"))
        },
        Support.Prop3dBinding {
            renderer: fog3d.renderer
            target: fog3d
            name: "height_enabled"
            property: "heightEnabled"
            value: fog3d.renderer.prop("height_enabled") === true
        },
        Support.Prop3dBinding {
            renderer: fog3d.renderer
            target: fog3d
            name: "least_intense_y"
            property: "leastIntenseY"
            value: Number(fog3d.renderer.prop("least_intense_y"))
        },
        Support.Prop3dBinding {
            renderer: fog3d.renderer
            target: fog3d
            name: "most_intense_y"
            property: "mostIntenseY"
            value: Number(fog3d.renderer.prop("most_intense_y"))
        },
        Support.Prop3dBinding {
            renderer: fog3d.renderer
            target: fog3d
            name: "height_curve"
            property: "heightCurve"
            value: Number(fog3d.renderer.prop("height_curve"))
        },
        Support.Prop3dBinding {
            renderer: fog3d.renderer
            target: fog3d
            name: "transmit_enabled"
            property: "transmitEnabled"
            value: fog3d.renderer.prop("transmit_enabled") === true
        },
        Support.Prop3dBinding {
            renderer: fog3d.renderer
            target: fog3d
            name: "transmit_curve"
            property: "transmitCurve"
            value: Number(fog3d.renderer.prop("transmit_curve"))
        }
    ]
}
