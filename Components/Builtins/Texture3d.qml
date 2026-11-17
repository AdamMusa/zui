import QtQuick
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// An image sampled by a material. Its content comes from an image asset,
// from procedural texture data, or from a live two-dimensional Zui
// control named by source_item, which is how a working interface ends up
// on a surface inside the scene.
Texture {
    id: texture3d

    required property var renderer

    sourceItem: renderer.findRenderedItem(renderer.prop("source_item", ""))
    textureData: renderer.childObjectOrReference(["procedural_texture_data", "procedural_sky_texture_data"], "texture_data")

    Support.Prop3dBinding {
        renderer: texture3d.renderer
        target: texture3d
        name: "source"
        property: "source"
        value: texture3d.renderer.assetUrl(texture3d.renderer.prop("source"))
    }

    Support.Prop3dBinding {
        renderer: texture3d.renderer
        target: texture3d
        name: "scale_u"
        property: "scaleU"
        value: Number(texture3d.renderer.prop("scale_u"))
    }

    Support.Prop3dBinding {
        renderer: texture3d.renderer
        target: texture3d
        name: "scale_v"
        property: "scaleV"
        value: Number(texture3d.renderer.prop("scale_v"))
    }

    Support.Prop3dBinding {
        renderer: texture3d.renderer
        target: texture3d
        name: "mapping_mode"
        property: "mappingMode"
        value: Value3d.enumeration(texture3d.renderer.prop("mapping_mode"), {
            "uv": Texture.UV,
            "environment": Texture.Environment,
            "light_probe": Texture.LightProbe
        }, Texture.UV)
    }

    Support.Prop3dBinding {
        renderer: texture3d.renderer
        target: texture3d
        name: "tiling_mode_horizontal"
        property: "tilingModeHorizontal"
        value: Value3d.enumeration(texture3d.renderer.prop("tiling_mode_horizontal"), {
            "clamp": Texture.ClampToEdge,
            "mirrored_repeat": Texture.MirroredRepeat,
            "repeat": Texture.Repeat
        }, Texture.ClampToEdge)
    }

    Support.Prop3dBinding {
        renderer: texture3d.renderer
        target: texture3d
        name: "tiling_mode_vertical"
        property: "tilingModeVertical"
        value: Value3d.enumeration(texture3d.renderer.prop("tiling_mode_vertical"), {
            "clamp": Texture.ClampToEdge,
            "mirrored_repeat": Texture.MirroredRepeat,
            "repeat": Texture.Repeat
        }, Texture.ClampToEdge)
    }

    Support.Prop3dBinding {
        renderer: texture3d.renderer
        target: texture3d
        name: "tiling_mode_depth"
        property: "tilingModeDepth"
        value: Value3d.enumeration(texture3d.renderer.prop("tiling_mode_depth"), {
            "clamp": Texture.ClampToEdge,
            "mirrored_repeat": Texture.MirroredRepeat,
            "repeat": Texture.Repeat
        }, Texture.ClampToEdge)
    }

    Support.Prop3dBinding {
        renderer: texture3d.renderer
        target: texture3d
        name: "rotation_uv"
        property: "rotationUV"
        value: Number(texture3d.renderer.prop("rotation_uv"))
    }

    Support.Prop3dBinding {
        renderer: texture3d.renderer
        target: texture3d
        name: "position_u"
        property: "positionU"
        value: Number(texture3d.renderer.prop("position_u"))
    }

    Support.Prop3dBinding {
        renderer: texture3d.renderer
        target: texture3d
        name: "position_v"
        property: "positionV"
        value: Number(texture3d.renderer.prop("position_v"))
    }

    Support.Prop3dBinding {
        renderer: texture3d.renderer
        target: texture3d
        name: "pivot_u"
        property: "pivotU"
        value: Number(texture3d.renderer.prop("pivot_u"))
    }

    Support.Prop3dBinding {
        renderer: texture3d.renderer
        target: texture3d
        name: "pivot_v"
        property: "pivotV"
        value: Number(texture3d.renderer.prop("pivot_v"))
    }

    Support.Prop3dBinding {
        renderer: texture3d.renderer
        target: texture3d
        name: "flip_u"
        property: "flipU"
        value: texture3d.renderer.prop("flip_u") === true
    }

    Support.Prop3dBinding {
        renderer: texture3d.renderer
        target: texture3d
        name: "flip_v"
        property: "flipV"
        value: texture3d.renderer.prop("flip_v") === true
    }

    Support.Prop3dBinding {
        renderer: texture3d.renderer
        target: texture3d
        name: "index_uv"
        property: "indexUV"
        value: Number(texture3d.renderer.prop("index_uv"))
    }

    Support.Prop3dBinding {
        renderer: texture3d.renderer
        target: texture3d
        name: "mag_filter"
        property: "magFilter"
        value: Value3d.enumeration(texture3d.renderer.prop("mag_filter"), {
            "none": Texture.None,
            "nearest": Texture.Nearest,
            "linear": Texture.Linear
        }, Texture.None)
    }

    Support.Prop3dBinding {
        renderer: texture3d.renderer
        target: texture3d
        name: "min_filter"
        property: "minFilter"
        value: Value3d.enumeration(texture3d.renderer.prop("min_filter"), {
            "none": Texture.None,
            "nearest": Texture.Nearest,
            "linear": Texture.Linear
        }, Texture.None)
    }

    Support.Prop3dBinding {
        renderer: texture3d.renderer
        target: texture3d
        name: "mip_filter"
        property: "mipFilter"
        value: Value3d.enumeration(texture3d.renderer.prop("mip_filter"), {
            "none": Texture.None,
            "nearest": Texture.Nearest,
            "linear": Texture.Linear
        }, Texture.None)
    }

    Support.Prop3dBinding {
        renderer: texture3d.renderer
        target: texture3d
        name: "generate_mipmaps"
        property: "generateMipmaps"
        value: texture3d.renderer.prop("generate_mipmaps") === true
    }

    Support.Prop3dBinding {
        renderer: texture3d.renderer
        target: texture3d
        name: "auto_orientation"
        property: "autoOrientation"
        value: texture3d.renderer.prop("auto_orientation") === true
    }
}
