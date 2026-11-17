import QtQuick
import QtQuick3D.Helpers
import "Support" as Support
import "Support/Value3d.js" as Value3d

// Texture content generated in Ruby rather than loaded from a file. A
// texture_3d names it as its texture_data.
ProceduralTextureData {
    id: proceduralTextureData

    required property var renderer

    Support.Prop3dBinding {
        renderer: proceduralTextureData.renderer
        target: proceduralTextureData
        name: "format"
        property: "format"
        value: Value3d.enumeration(proceduralTextureData.renderer.prop("format"), {
            "none": ProceduralTextureData.None,
            "rgba8": ProceduralTextureData.RGBA8,
            "rgba16f": ProceduralTextureData.RGBA16F,
            "rgba32f": ProceduralTextureData.RGBA32F,
            "rgbe8": ProceduralTextureData.RGBE8,
            "r8": ProceduralTextureData.R8,
            "r16": ProceduralTextureData.R16,
            "r16f": ProceduralTextureData.R16F,
            "r32f": ProceduralTextureData.R32F,
            "bc1": ProceduralTextureData.BC1,
            "bc2": ProceduralTextureData.BC2,
            "bc3": ProceduralTextureData.BC3,
            "bc4": ProceduralTextureData.BC4,
            "bc5": ProceduralTextureData.BC5,
            "bc6h": ProceduralTextureData.BC6H,
            "bc7": ProceduralTextureData.BC7,
            "dxt1_rgba": ProceduralTextureData.DXT1_RGBA,
            "dxt1_rgb": ProceduralTextureData.DXT1_RGB,
            "dxt3_rgba": ProceduralTextureData.DXT3_RGBA,
            "dxt5_rgba": ProceduralTextureData.DXT5_RGBA,
            "etc2_rgb8": ProceduralTextureData.ETC2_RGB8,
            "etc2_rgb8a1": ProceduralTextureData.ETC2_RGB8A1,
            "etc2_rgba8": ProceduralTextureData.ETC2_RGBA8,
            "astc_4x4": ProceduralTextureData.ASTC_4x4,
            "astc_5x4": ProceduralTextureData.ASTC_5x4,
            "astc_5x5": ProceduralTextureData.ASTC_5x5,
            "astc_6x5": ProceduralTextureData.ASTC_6x5,
            "astc_6x6": ProceduralTextureData.ASTC_6x6,
            "astc_8x5": ProceduralTextureData.ASTC_8x5,
            "astc_8x6": ProceduralTextureData.ASTC_8x6,
            "astc_8x8": ProceduralTextureData.ASTC_8x8,
            "astc_10x5": ProceduralTextureData.ASTC_10x5,
            "astc_10x6": ProceduralTextureData.ASTC_10x6,
            "astc_10x8": ProceduralTextureData.ASTC_10x8,
            "astc_10x10": ProceduralTextureData.ASTC_10x10,
            "astc_12x10": ProceduralTextureData.ASTC_12x10,
            "astc_12x12": ProceduralTextureData.ASTC_12x12
        }, ProceduralTextureData.None)
    }

    Support.Prop3dBinding {
        renderer: proceduralTextureData.renderer
        target: proceduralTextureData
        name: "width"
        property: "width"
        value: Number(proceduralTextureData.renderer.prop("width"))
    }

    Support.Prop3dBinding {
        renderer: proceduralTextureData.renderer
        target: proceduralTextureData
        name: "height"
        property: "height"
        value: Number(proceduralTextureData.renderer.prop("height"))
    }

    Support.Prop3dBinding {
        renderer: proceduralTextureData.renderer
        target: proceduralTextureData
        name: "depth"
        property: "depth"
        value: Number(proceduralTextureData.renderer.prop("depth"))
    }

    Support.Prop3dBinding {
        renderer: proceduralTextureData.renderer
        target: proceduralTextureData
        name: "has_transparency"
        property: "hasTransparency"
        value: proceduralTextureData.renderer.prop("has_transparency") === true
    }

    Support.Prop3dBinding {
        renderer: proceduralTextureData.renderer
        target: proceduralTextureData
        name: "texture_data"
        property: "textureData"
        value: String(proceduralTextureData.renderer.prop("texture_data"))
    }
}
