import QtQuick
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// A material whose shading is written as a vertex and fragment shader.
// shading_mode picks whether Qt's lighting pipeline runs at all, and the
// four blend factors give the material its own blending equation.
CustomMaterial {
    id: customMaterial

    required property var renderer

    // Uniforms a custom material's shaders can read. QML needs a declared
    // property per uniform, so Zui offers one documented set rather than
    // letting each shader invent its own names.
    property real time: Number(renderer.prop("time", 0))
    property real intensity: Number(renderer.prop("intensity", 1))
    property real amount: Number(renderer.prop("amount", 1))
    property real radius: Number(renderer.prop("radius", 1))
    property real progress: Number(renderer.prop("progress", 0))
    property real frequency: Number(renderer.prop("frequency", 1))
    property real amplitude: Number(renderer.prop("amplitude", 0.02))
    property color tint: renderer.prop("tint", "white")
    property color tint2: renderer.prop("tint2", "black")
    property vector4d parameters: Value3d.vector4d(renderer.prop("parameters", null), 0, 0, 0, 0)

    Support.Prop3dBinding {
        renderer: customMaterial.renderer
        target: customMaterial
        name: "shading_mode"
        property: "shadingMode"
        value: Value3d.enumeration(customMaterial.renderer.prop("shading_mode"), {
            "unshaded": CustomMaterial.Unshaded,
            "shaded": CustomMaterial.Shaded
        }, CustomMaterial.Unshaded)
    }

    Support.Prop3dBinding {
        renderer: customMaterial.renderer
        target: customMaterial
        name: "fragment_shader"
        property: "fragmentShader"
        value: customMaterial.renderer.assetUrl(customMaterial.renderer.prop("fragment_shader"))
    }

    Support.Prop3dBinding {
        renderer: customMaterial.renderer
        target: customMaterial
        name: "vertex_shader"
        property: "vertexShader"
        value: customMaterial.renderer.assetUrl(customMaterial.renderer.prop("vertex_shader"))
    }

    Support.Prop3dBinding {
        renderer: customMaterial.renderer
        target: customMaterial
        name: "source_blend"
        property: "sourceBlend"
        value: Value3d.enumeration(customMaterial.renderer.prop("source_blend"), {
            "no_blend": CustomMaterial.NoBlend,
            "zero": CustomMaterial.Zero,
            "one": CustomMaterial.One,
            "src_color": CustomMaterial.SrcColor,
            "one_minus_src_color": CustomMaterial.OneMinusSrcColor,
            "dst_color": CustomMaterial.DstColor,
            "one_minus_dst_color": CustomMaterial.OneMinusDstColor,
            "src_alpha": CustomMaterial.SrcAlpha,
            "one_minus_src_alpha": CustomMaterial.OneMinusSrcAlpha,
            "dst_alpha": CustomMaterial.DstAlpha,
            "one_minus_dst_alpha": CustomMaterial.OneMinusDstAlpha,
            "constant_color": CustomMaterial.ConstantColor,
            "one_minus_constant_color": CustomMaterial.OneMinusConstantColor,
            "constant_alpha": CustomMaterial.ConstantAlpha,
            "one_minus_constant_alpha": CustomMaterial.OneMinusConstantAlpha,
            "src_alpha_saturate": CustomMaterial.SrcAlphaSaturate
        }, CustomMaterial.NoBlend)
    }

    Support.Prop3dBinding {
        renderer: customMaterial.renderer
        target: customMaterial
        name: "destination_blend"
        property: "destinationBlend"
        value: Value3d.enumeration(customMaterial.renderer.prop("destination_blend"), {
            "no_blend": CustomMaterial.NoBlend,
            "zero": CustomMaterial.Zero,
            "one": CustomMaterial.One,
            "src_color": CustomMaterial.SrcColor,
            "one_minus_src_color": CustomMaterial.OneMinusSrcColor,
            "dst_color": CustomMaterial.DstColor,
            "one_minus_dst_color": CustomMaterial.OneMinusDstColor,
            "src_alpha": CustomMaterial.SrcAlpha,
            "one_minus_src_alpha": CustomMaterial.OneMinusSrcAlpha,
            "dst_alpha": CustomMaterial.DstAlpha,
            "one_minus_dst_alpha": CustomMaterial.OneMinusDstAlpha,
            "constant_color": CustomMaterial.ConstantColor,
            "one_minus_constant_color": CustomMaterial.OneMinusConstantColor,
            "constant_alpha": CustomMaterial.ConstantAlpha,
            "one_minus_constant_alpha": CustomMaterial.OneMinusConstantAlpha,
            "src_alpha_saturate": CustomMaterial.SrcAlphaSaturate
        }, CustomMaterial.NoBlend)
    }

    Support.Prop3dBinding {
        renderer: customMaterial.renderer
        target: customMaterial
        name: "source_alpha_blend"
        property: "sourceAlphaBlend"
        value: Value3d.enumeration(customMaterial.renderer.prop("source_alpha_blend"), {
            "no_blend": CustomMaterial.NoBlend,
            "zero": CustomMaterial.Zero,
            "one": CustomMaterial.One,
            "src_color": CustomMaterial.SrcColor,
            "one_minus_src_color": CustomMaterial.OneMinusSrcColor,
            "dst_color": CustomMaterial.DstColor,
            "one_minus_dst_color": CustomMaterial.OneMinusDstColor,
            "src_alpha": CustomMaterial.SrcAlpha,
            "one_minus_src_alpha": CustomMaterial.OneMinusSrcAlpha,
            "dst_alpha": CustomMaterial.DstAlpha,
            "one_minus_dst_alpha": CustomMaterial.OneMinusDstAlpha,
            "constant_color": CustomMaterial.ConstantColor,
            "one_minus_constant_color": CustomMaterial.OneMinusConstantColor,
            "constant_alpha": CustomMaterial.ConstantAlpha,
            "one_minus_constant_alpha": CustomMaterial.OneMinusConstantAlpha,
            "src_alpha_saturate": CustomMaterial.SrcAlphaSaturate
        }, CustomMaterial.NoBlend)
    }

    Support.Prop3dBinding {
        renderer: customMaterial.renderer
        target: customMaterial
        name: "destination_alpha_blend"
        property: "destinationAlphaBlend"
        value: Value3d.enumeration(customMaterial.renderer.prop("destination_alpha_blend"), {
            "no_blend": CustomMaterial.NoBlend,
            "zero": CustomMaterial.Zero,
            "one": CustomMaterial.One,
            "src_color": CustomMaterial.SrcColor,
            "one_minus_src_color": CustomMaterial.OneMinusSrcColor,
            "dst_color": CustomMaterial.DstColor,
            "one_minus_dst_color": CustomMaterial.OneMinusDstColor,
            "src_alpha": CustomMaterial.SrcAlpha,
            "one_minus_src_alpha": CustomMaterial.OneMinusSrcAlpha,
            "dst_alpha": CustomMaterial.DstAlpha,
            "one_minus_dst_alpha": CustomMaterial.OneMinusDstAlpha,
            "constant_color": CustomMaterial.ConstantColor,
            "one_minus_constant_color": CustomMaterial.OneMinusConstantColor,
            "constant_alpha": CustomMaterial.ConstantAlpha,
            "one_minus_constant_alpha": CustomMaterial.OneMinusConstantAlpha,
            "src_alpha_saturate": CustomMaterial.SrcAlphaSaturate
        }, CustomMaterial.NoBlend)
    }

    Support.Prop3dBinding {
        renderer: customMaterial.renderer
        target: customMaterial
        name: "always_dirty"
        property: "alwaysDirty"
        value: customMaterial.renderer.prop("always_dirty") === true
    }

    Support.Prop3dBinding {
        renderer: customMaterial.renderer
        target: customMaterial
        name: "line_width"
        property: "lineWidth"
        value: Number(customMaterial.renderer.prop("line_width"))
    }

    Support.Prop3dBinding {
        renderer: customMaterial.renderer
        target: customMaterial
        name: "light_probe"
        property: "lightProbe"
        value: customMaterial.renderer.sceneObject(customMaterial.renderer.prop("light_probe"))
    }

    Support.Prop3dBinding {
        renderer: customMaterial.renderer
        target: customMaterial
        name: "cull_mode"
        property: "cullMode"
        value: Value3d.enumeration(customMaterial.renderer.prop("cull_mode"), {
            "back": CustomMaterial.BackFaceCulling,
            "front": CustomMaterial.FrontFaceCulling,
            "none": CustomMaterial.NoCulling
        }, CustomMaterial.BackFaceCulling)
    }

    Support.Prop3dBinding {
        renderer: customMaterial.renderer
        target: customMaterial
        name: "depth_draw_mode"
        property: "depthDrawMode"
        value: Value3d.enumeration(customMaterial.renderer.prop("depth_draw_mode"), {
            "opaque_only": CustomMaterial.OpaqueOnlyDepthDraw,
            "always": CustomMaterial.AlwaysDepthDraw,
            "never": CustomMaterial.NeverDepthDraw,
            "opaque_prepass": CustomMaterial.OpaquePrePassDepthDraw
        }, CustomMaterial.OpaqueOnlyDepthDraw)
    }
}
