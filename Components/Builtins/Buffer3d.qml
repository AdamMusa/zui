import QtQuick
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// An intermediate render target a pass can write to and a later pass can
// sample. size_multiplier scales it against the view, so 0.5 halves it.
Buffer {
    id: buffer3d

    required property var renderer

    property list<QtObject> propertyBindings: [
        Support.Prop3dBinding {
            renderer: buffer3d.renderer
            target: buffer3d
            name: "texture_filter_operation"
            property: "textureFilterOperation"
            value: Value3d.enumeration(buffer3d.renderer.prop("texture_filter_operation"), {
                "unknown": Buffer.Unknown,
                "nearest": Buffer.Nearest,
                "linear": Buffer.Linear
            }, Buffer.Unknown)
        },
        Support.Prop3dBinding {
            renderer: buffer3d.renderer
            target: buffer3d
            name: "texture_coord_operation"
            property: "textureCoordOperation"
            value: Value3d.enumeration(buffer3d.renderer.prop("texture_coord_operation"), {
                "unknown": Buffer.Unknown,
                "clamp": Buffer.ClampToEdge,
                "mirrored_repeat": Buffer.MirroredRepeat,
                "repeat": Buffer.Repeat
            }, Buffer.Unknown)
        },
        Support.Prop3dBinding {
            renderer: buffer3d.renderer
            target: buffer3d
            name: "buffer_flags"
            property: "bufferFlags"
            value: Value3d.enumeration(buffer3d.renderer.prop("buffer_flags"), {
                "none": Buffer.None,
                "scene_lifetime": Buffer.SceneLifetime
            }, Buffer.None)
        },
        Support.Prop3dBinding {
            renderer: buffer3d.renderer
            target: buffer3d
            name: "format"
            property: "format"
            value: Value3d.enumeration(buffer3d.renderer.prop("format"), {
                "unknown": Buffer.Unknown,
                "rgba8": Buffer.RGBA8,
                "rgba16f": Buffer.RGBA16F,
                "rgba32f": Buffer.RGBA32F,
                "r8": Buffer.R8,
                "r16": Buffer.R16,
                "r16f": Buffer.R16F,
                "r32f": Buffer.R32F
            }, Buffer.Unknown)
        },
        Support.Prop3dBinding {
            renderer: buffer3d.renderer
            target: buffer3d
            name: "size_multiplier"
            property: "sizeMultiplier"
            value: Number(buffer3d.renderer.prop("size_multiplier"))
        },
        Support.Prop3dBinding {
            renderer: buffer3d.renderer
            target: buffer3d
            name: "name"
            property: "name"
            value: String(buffer3d.renderer.prop("name"))
        }
    ]
}
