import QtQuick
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// The pre-physically-based material: a diffuse colour with an explicit
// specular model, bump and translucency maps. Kept for scenes authored
// against it; new work wants principled_material.
DefaultMaterial {
    id: defaultMaterial

    required property var renderer

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "lighting"
        property: "lighting"
        value: Value3d.enumeration(defaultMaterial.renderer.prop("lighting"), {
            "none": DefaultMaterial.NoLighting,
            "fragment": DefaultMaterial.FragmentLighting
        }, DefaultMaterial.NoLighting)
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "blend_mode"
        property: "blendMode"
        value: Value3d.enumeration(defaultMaterial.renderer.prop("blend_mode"), {
            "source_over": DefaultMaterial.SourceOver,
            "screen": DefaultMaterial.Screen,
            "multiply": DefaultMaterial.Multiply
        }, DefaultMaterial.SourceOver)
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "diffuse_color"
        property: "diffuseColor"
        value: defaultMaterial.renderer.prop("diffuse_color")
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "diffuse_map"
        property: "diffuseMap"
        value: defaultMaterial.renderer.sceneObject(defaultMaterial.renderer.prop("diffuse_map"))
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "emissive_factor"
        property: "emissiveFactor"
        value: Value3d.vector3d(defaultMaterial.renderer.prop("emissive_factor"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "emissive_map"
        property: "emissiveMap"
        value: defaultMaterial.renderer.sceneObject(defaultMaterial.renderer.prop("emissive_map"))
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "specular_reflection_map"
        property: "specularReflectionMap"
        value: defaultMaterial.renderer.sceneObject(defaultMaterial.renderer.prop("specular_reflection_map"))
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "specular_map"
        property: "specularMap"
        value: defaultMaterial.renderer.sceneObject(defaultMaterial.renderer.prop("specular_map"))
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "specular_model"
        property: "specularModel"
        value: Value3d.enumeration(defaultMaterial.renderer.prop("specular_model"), {
            "default": DefaultMaterial.Default,
            "kggx": DefaultMaterial.KGGX
        }, DefaultMaterial.Default)
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "specular_tint"
        property: "specularTint"
        value: defaultMaterial.renderer.prop("specular_tint")
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "index_of_refraction"
        property: "indexOfRefraction"
        value: Number(defaultMaterial.renderer.prop("index_of_refraction"))
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "fresnel_power"
        property: "fresnelPower"
        value: Number(defaultMaterial.renderer.prop("fresnel_power"))
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "specular_amount"
        property: "specularAmount"
        value: Number(defaultMaterial.renderer.prop("specular_amount"))
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "specular_roughness"
        property: "specularRoughness"
        value: Number(defaultMaterial.renderer.prop("specular_roughness"))
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "roughness_map"
        property: "roughnessMap"
        value: defaultMaterial.renderer.sceneObject(defaultMaterial.renderer.prop("roughness_map"))
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "roughness_channel"
        property: "roughnessChannel"
        value: Value3d.enumeration(defaultMaterial.renderer.prop("roughness_channel"), {
            "r": DefaultMaterial.R,
            "g": DefaultMaterial.G,
            "b": DefaultMaterial.B,
            "a": DefaultMaterial.A
        }, DefaultMaterial.R)
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "opacity"
        property: "opacity"
        value: Number(defaultMaterial.renderer.prop("opacity"))
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "opacity_map"
        property: "opacityMap"
        value: defaultMaterial.renderer.sceneObject(defaultMaterial.renderer.prop("opacity_map"))
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "opacity_channel"
        property: "opacityChannel"
        value: Value3d.enumeration(defaultMaterial.renderer.prop("opacity_channel"), {
            "r": DefaultMaterial.R,
            "g": DefaultMaterial.G,
            "b": DefaultMaterial.B,
            "a": DefaultMaterial.A
        }, DefaultMaterial.R)
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "bump_map"
        property: "bumpMap"
        value: defaultMaterial.renderer.sceneObject(defaultMaterial.renderer.prop("bump_map"))
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "bump_amount"
        property: "bumpAmount"
        value: Number(defaultMaterial.renderer.prop("bump_amount"))
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "normal_map"
        property: "normalMap"
        value: defaultMaterial.renderer.sceneObject(defaultMaterial.renderer.prop("normal_map"))
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "translucency_map"
        property: "translucencyMap"
        value: defaultMaterial.renderer.sceneObject(defaultMaterial.renderer.prop("translucency_map"))
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "translucency_channel"
        property: "translucencyChannel"
        value: Value3d.enumeration(defaultMaterial.renderer.prop("translucency_channel"), {
            "r": DefaultMaterial.R,
            "g": DefaultMaterial.G,
            "b": DefaultMaterial.B,
            "a": DefaultMaterial.A
        }, DefaultMaterial.R)
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "translucent_falloff"
        property: "translucentFalloff"
        value: Number(defaultMaterial.renderer.prop("translucent_falloff"))
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "diffuse_light_wrap"
        property: "diffuseLightWrap"
        value: Number(defaultMaterial.renderer.prop("diffuse_light_wrap"))
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "vertex_colors_enabled"
        property: "vertexColorsEnabled"
        value: defaultMaterial.renderer.prop("vertex_colors_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "point_size"
        property: "pointSize"
        value: Number(defaultMaterial.renderer.prop("point_size"))
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "line_width"
        property: "lineWidth"
        value: Number(defaultMaterial.renderer.prop("line_width"))
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "light_probe"
        property: "lightProbe"
        value: defaultMaterial.renderer.sceneObject(defaultMaterial.renderer.prop("light_probe"))
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "cull_mode"
        property: "cullMode"
        value: Value3d.enumeration(defaultMaterial.renderer.prop("cull_mode"), {
            "back": DefaultMaterial.BackFaceCulling,
            "front": DefaultMaterial.FrontFaceCulling,
            "none": DefaultMaterial.NoCulling
        }, DefaultMaterial.BackFaceCulling)
    }

    Support.Prop3dBinding {
        renderer: defaultMaterial.renderer
        target: defaultMaterial
        name: "depth_draw_mode"
        property: "depthDrawMode"
        value: Value3d.enumeration(defaultMaterial.renderer.prop("depth_draw_mode"), {
            "opaque_only": DefaultMaterial.OpaqueOnlyDepthDraw,
            "always": DefaultMaterial.AlwaysDepthDraw,
            "never": DefaultMaterial.NeverDepthDraw,
            "opaque_prepass": DefaultMaterial.OpaquePrePassDepthDraw
        }, DefaultMaterial.OpaqueOnlyDepthDraw)
    }
}
