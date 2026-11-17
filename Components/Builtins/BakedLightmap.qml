import QtQuick
import QtQuick3D
import "Support" as Support

// Names the baked lightmap a model loads, and whether to use it.
BakedLightmap {
    id: bakedLightmap

    required property var renderer

    property list<QtObject> propertyBindings: [
        Support.Prop3dBinding {
            renderer: bakedLightmap.renderer
            target: bakedLightmap
            name: "enabled"
            property: "enabled"
            value: bakedLightmap.renderer.prop("enabled") === true
        },
        Support.Prop3dBinding {
            renderer: bakedLightmap.renderer
            target: bakedLightmap
            name: "key"
            property: "key"
            value: String(bakedLightmap.renderer.prop("key"))
        },
        Support.Prop3dBinding {
            renderer: bakedLightmap.renderer
            target: bakedLightmap
            name: "load_prefix"
            property: "loadPrefix"
            value: String(bakedLightmap.renderer.prop("load_prefix"))
        }
    ]
}
