import QtQuick
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// A six-faced texture, for a skybox, an environment reflection or a
// point light's shadow cube.
CubeMapTexture {
    id: cubeMapTexture

    required property var renderer

    sourceItem: renderer.findRenderedItem(renderer.prop("source_item", ""))
    textureData: renderer.childObjectOrReference(["procedural_texture_data", "procedural_sky_texture_data"], "texture_data")

    Support.Prop3dBinding {
        renderer: cubeMapTexture.renderer
        target: cubeMapTexture
        name: "source"
        property: "source"
        value: cubeMapTexture.renderer.assetUrl(cubeMapTexture.renderer.prop("source"))
    }

    Support.Prop3dBinding {
        renderer: cubeMapTexture.renderer
        target: cubeMapTexture
        name: "scale_u"
        property: "scaleU"
        value: Number(cubeMapTexture.renderer.prop("scale_u"))
    }

    Support.Prop3dBinding {
        renderer: cubeMapTexture.renderer
        target: cubeMapTexture
        name: "scale_v"
        property: "scaleV"
        value: Number(cubeMapTexture.renderer.prop("scale_v"))
    }

    Support.Prop3dBinding {
        renderer: cubeMapTexture.renderer
        target: cubeMapTexture
        name: "mapping_mode"
        property: "mappingMode"
        value: Value3d.enumeration(cubeMapTexture.renderer.prop("mapping_mode"), {
            "uv": CubeMapTexture.UV,
            "environment": CubeMapTexture.Environment,
            "light_probe": CubeMapTexture.LightProbe
        }, CubeMapTexture.UV)
    }

    Support.Prop3dBinding {
        renderer: cubeMapTexture.renderer
        target: cubeMapTexture
        name: "tiling_mode_horizontal"
        property: "tilingModeHorizontal"
        value: Value3d.enumeration(cubeMapTexture.renderer.prop("tiling_mode_horizontal"), {
            "clamp": CubeMapTexture.ClampToEdge,
            "mirrored_repeat": CubeMapTexture.MirroredRepeat,
            "repeat": CubeMapTexture.Repeat
        }, CubeMapTexture.ClampToEdge)
    }

    Support.Prop3dBinding {
        renderer: cubeMapTexture.renderer
        target: cubeMapTexture
        name: "tiling_mode_vertical"
        property: "tilingModeVertical"
        value: Value3d.enumeration(cubeMapTexture.renderer.prop("tiling_mode_vertical"), {
            "clamp": CubeMapTexture.ClampToEdge,
            "mirrored_repeat": CubeMapTexture.MirroredRepeat,
            "repeat": CubeMapTexture.Repeat
        }, CubeMapTexture.ClampToEdge)
    }

    Support.Prop3dBinding {
        renderer: cubeMapTexture.renderer
        target: cubeMapTexture
        name: "tiling_mode_depth"
        property: "tilingModeDepth"
        value: Value3d.enumeration(cubeMapTexture.renderer.prop("tiling_mode_depth"), {
            "clamp": CubeMapTexture.ClampToEdge,
            "mirrored_repeat": CubeMapTexture.MirroredRepeat,
            "repeat": CubeMapTexture.Repeat
        }, CubeMapTexture.ClampToEdge)
    }

    Support.Prop3dBinding {
        renderer: cubeMapTexture.renderer
        target: cubeMapTexture
        name: "rotation_uv"
        property: "rotationUV"
        value: Number(cubeMapTexture.renderer.prop("rotation_uv"))
    }

    Support.Prop3dBinding {
        renderer: cubeMapTexture.renderer
        target: cubeMapTexture
        name: "position_u"
        property: "positionU"
        value: Number(cubeMapTexture.renderer.prop("position_u"))
    }

    Support.Prop3dBinding {
        renderer: cubeMapTexture.renderer
        target: cubeMapTexture
        name: "position_v"
        property: "positionV"
        value: Number(cubeMapTexture.renderer.prop("position_v"))
    }

    Support.Prop3dBinding {
        renderer: cubeMapTexture.renderer
        target: cubeMapTexture
        name: "pivot_u"
        property: "pivotU"
        value: Number(cubeMapTexture.renderer.prop("pivot_u"))
    }

    Support.Prop3dBinding {
        renderer: cubeMapTexture.renderer
        target: cubeMapTexture
        name: "pivot_v"
        property: "pivotV"
        value: Number(cubeMapTexture.renderer.prop("pivot_v"))
    }

    Support.Prop3dBinding {
        renderer: cubeMapTexture.renderer
        target: cubeMapTexture
        name: "flip_u"
        property: "flipU"
        value: cubeMapTexture.renderer.prop("flip_u") === true
    }

    Support.Prop3dBinding {
        renderer: cubeMapTexture.renderer
        target: cubeMapTexture
        name: "flip_v"
        property: "flipV"
        value: cubeMapTexture.renderer.prop("flip_v") === true
    }

    Support.Prop3dBinding {
        renderer: cubeMapTexture.renderer
        target: cubeMapTexture
        name: "index_uv"
        property: "indexUV"
        value: Number(cubeMapTexture.renderer.prop("index_uv"))
    }

    Support.Prop3dBinding {
        renderer: cubeMapTexture.renderer
        target: cubeMapTexture
        name: "mag_filter"
        property: "magFilter"
        value: Value3d.enumeration(cubeMapTexture.renderer.prop("mag_filter"), {
            "none": CubeMapTexture.None,
            "nearest": CubeMapTexture.Nearest,
            "linear": CubeMapTexture.Linear
        }, CubeMapTexture.None)
    }

    Support.Prop3dBinding {
        renderer: cubeMapTexture.renderer
        target: cubeMapTexture
        name: "min_filter"
        property: "minFilter"
        value: Value3d.enumeration(cubeMapTexture.renderer.prop("min_filter"), {
            "none": CubeMapTexture.None,
            "nearest": CubeMapTexture.Nearest,
            "linear": CubeMapTexture.Linear
        }, CubeMapTexture.None)
    }

    Support.Prop3dBinding {
        renderer: cubeMapTexture.renderer
        target: cubeMapTexture
        name: "mip_filter"
        property: "mipFilter"
        value: Value3d.enumeration(cubeMapTexture.renderer.prop("mip_filter"), {
            "none": CubeMapTexture.None,
            "nearest": CubeMapTexture.Nearest,
            "linear": CubeMapTexture.Linear
        }, CubeMapTexture.None)
    }

    Support.Prop3dBinding {
        renderer: cubeMapTexture.renderer
        target: cubeMapTexture
        name: "generate_mipmaps"
        property: "generateMipmaps"
        value: cubeMapTexture.renderer.prop("generate_mipmaps") === true
    }

    Support.Prop3dBinding {
        renderer: cubeMapTexture.renderer
        target: cubeMapTexture
        name: "auto_orientation"
        property: "autoOrientation"
        value: cubeMapTexture.renderer.prop("auto_orientation") === true
    }
}
