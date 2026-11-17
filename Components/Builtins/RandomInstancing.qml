import QtQuick
import QtQuick3D.Helpers
import "Support" as Support
import "Support/Value3d.js" as Value3d

// Generates instances from random values inside declared ranges, for a
// field of scattered geometry. Each range is an instance_range declared
// in the scene and named here, and random_seed makes the result repeat.
RandomInstancing {
    id: randomInstancing

    required property var renderer

    position: renderer.sceneObject(renderer.prop("position_range", ""))
    scale: renderer.sceneObject(renderer.prop("scale_range", ""))
    rotation: renderer.sceneObject(renderer.prop("rotation_range", ""))
    color: renderer.sceneObject(renderer.prop("color_range", ""))
    customData: renderer.sceneObject(renderer.prop("custom_data_range", ""))

    property list<QtObject> propertyBindings: [
        Support.Prop3dBinding {
            renderer: randomInstancing.renderer
            target: randomInstancing
            name: "instance_count"
            property: "instanceCount"
            value: Number(randomInstancing.renderer.prop("instance_count"))
        },
        Support.Prop3dBinding {
            renderer: randomInstancing.renderer
            target: randomInstancing
            name: "color_model"
            property: "colorModel"
            value: Value3d.enumeration(randomInstancing.renderer.prop("color_model"), {
                "rgb": RandomInstancing.RGB,
                "hsv": RandomInstancing.HSV,
                "hsl": RandomInstancing.HSL
            }, RandomInstancing.RGB)
        },
        Support.Prop3dBinding {
            renderer: randomInstancing.renderer
            target: randomInstancing
            name: "random_seed"
            property: "randomSeed"
            value: Number(randomInstancing.renderer.prop("random_seed"))
        },
        Support.Prop3dBinding {
            renderer: randomInstancing.renderer
            target: randomInstancing
            name: "instance_count_override"
            property: "instanceCountOverride"
            value: Number(randomInstancing.renderer.prop("instance_count_override"))
        },
        Support.Prop3dBinding {
            renderer: randomInstancing.renderer
            target: randomInstancing
            name: "has_transparency"
            property: "hasTransparency"
            value: randomInstancing.renderer.prop("has_transparency") === true
        },
        Support.Prop3dBinding {
            renderer: randomInstancing.renderer
            target: randomInstancing
            name: "depth_sorting_enabled"
            property: "depthSortingEnabled"
            value: randomInstancing.renderer.prop("depth_sorting_enabled") === true
        }
    ]
}
