import QtQuick
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// The metal-roughness physically based material, and the one to reach for
// by default. Every texture slot takes the Ruby id of a texture_3d,
// cube_map_texture or texture_data declared anywhere in the scene.
PrincipledMaterial {
    id: principledMaterial

    required property var renderer

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "lighting"
        property: "lighting"
        value: Value3d.enumeration(principledMaterial.renderer.prop("lighting"), {
            "none": PrincipledMaterial.NoLighting,
            "fragment": PrincipledMaterial.FragmentLighting
        }, PrincipledMaterial.NoLighting)
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "blend_mode"
        property: "blendMode"
        value: Value3d.enumeration(principledMaterial.renderer.prop("blend_mode"), {
            "source_over": PrincipledMaterial.SourceOver,
            "screen": PrincipledMaterial.Screen,
            "multiply": PrincipledMaterial.Multiply
        }, PrincipledMaterial.SourceOver)
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "base_color"
        property: "baseColor"
        value: principledMaterial.renderer.prop("base_color")
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "base_color_map"
        property: "baseColorMap"
        value: principledMaterial.renderer.sceneObject(principledMaterial.renderer.prop("base_color_map"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "base_color_single_channel_enabled"
        property: "baseColorSingleChannelEnabled"
        value: principledMaterial.renderer.prop("base_color_single_channel_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "base_color_channel"
        property: "baseColorChannel"
        value: Value3d.enumeration(principledMaterial.renderer.prop("base_color_channel"), {
            "r": PrincipledMaterial.R,
            "g": PrincipledMaterial.G,
            "b": PrincipledMaterial.B,
            "a": PrincipledMaterial.A
        }, PrincipledMaterial.R)
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "metalness"
        property: "metalness"
        value: Number(principledMaterial.renderer.prop("metalness"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "metalness_map"
        property: "metalnessMap"
        value: principledMaterial.renderer.sceneObject(principledMaterial.renderer.prop("metalness_map"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "metalness_channel"
        property: "metalnessChannel"
        value: Value3d.enumeration(principledMaterial.renderer.prop("metalness_channel"), {
            "r": PrincipledMaterial.R,
            "g": PrincipledMaterial.G,
            "b": PrincipledMaterial.B,
            "a": PrincipledMaterial.A
        }, PrincipledMaterial.R)
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "specular_amount"
        property: "specularAmount"
        value: Number(principledMaterial.renderer.prop("specular_amount"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "specular_map"
        property: "specularMap"
        value: principledMaterial.renderer.sceneObject(principledMaterial.renderer.prop("specular_map"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "specular_tint"
        property: "specularTint"
        value: Number(principledMaterial.renderer.prop("specular_tint"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "specular_single_channel_enabled"
        property: "specularSingleChannelEnabled"
        value: principledMaterial.renderer.prop("specular_single_channel_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "specular_channel"
        property: "specularChannel"
        value: Value3d.enumeration(principledMaterial.renderer.prop("specular_channel"), {
            "r": PrincipledMaterial.R,
            "g": PrincipledMaterial.G,
            "b": PrincipledMaterial.B,
            "a": PrincipledMaterial.A
        }, PrincipledMaterial.R)
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "roughness"
        property: "roughness"
        value: Number(principledMaterial.renderer.prop("roughness"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "roughness_map"
        property: "roughnessMap"
        value: principledMaterial.renderer.sceneObject(principledMaterial.renderer.prop("roughness_map"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "roughness_channel"
        property: "roughnessChannel"
        value: Value3d.enumeration(principledMaterial.renderer.prop("roughness_channel"), {
            "r": PrincipledMaterial.R,
            "g": PrincipledMaterial.G,
            "b": PrincipledMaterial.B,
            "a": PrincipledMaterial.A
        }, PrincipledMaterial.R)
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "emissive_factor"
        property: "emissiveFactor"
        value: Value3d.vector3d(principledMaterial.renderer.prop("emissive_factor"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "emissive_map"
        property: "emissiveMap"
        value: principledMaterial.renderer.sceneObject(principledMaterial.renderer.prop("emissive_map"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "emissive_single_channel_enabled"
        property: "emissiveSingleChannelEnabled"
        value: principledMaterial.renderer.prop("emissive_single_channel_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "emissive_channel"
        property: "emissiveChannel"
        value: Value3d.enumeration(principledMaterial.renderer.prop("emissive_channel"), {
            "r": PrincipledMaterial.R,
            "g": PrincipledMaterial.G,
            "b": PrincipledMaterial.B,
            "a": PrincipledMaterial.A
        }, PrincipledMaterial.R)
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "invert_opacity_map_value"
        property: "invertOpacityMapValue"
        value: principledMaterial.renderer.prop("invert_opacity_map_value") === true
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "opacity"
        property: "opacity"
        value: Number(principledMaterial.renderer.prop("opacity"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "opacity_map"
        property: "opacityMap"
        value: principledMaterial.renderer.sceneObject(principledMaterial.renderer.prop("opacity_map"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "opacity_channel"
        property: "opacityChannel"
        value: Value3d.enumeration(principledMaterial.renderer.prop("opacity_channel"), {
            "r": PrincipledMaterial.R,
            "g": PrincipledMaterial.G,
            "b": PrincipledMaterial.B,
            "a": PrincipledMaterial.A
        }, PrincipledMaterial.R)
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "normal_map"
        property: "normalMap"
        value: principledMaterial.renderer.sceneObject(principledMaterial.renderer.prop("normal_map"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "normal_strength"
        property: "normalStrength"
        value: Number(principledMaterial.renderer.prop("normal_strength"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "specular_reflection_map"
        property: "specularReflectionMap"
        value: principledMaterial.renderer.sceneObject(principledMaterial.renderer.prop("specular_reflection_map"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "occlusion_map"
        property: "occlusionMap"
        value: principledMaterial.renderer.sceneObject(principledMaterial.renderer.prop("occlusion_map"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "occlusion_channel"
        property: "occlusionChannel"
        value: Value3d.enumeration(principledMaterial.renderer.prop("occlusion_channel"), {
            "r": PrincipledMaterial.R,
            "g": PrincipledMaterial.G,
            "b": PrincipledMaterial.B,
            "a": PrincipledMaterial.A
        }, PrincipledMaterial.R)
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "occlusion_amount"
        property: "occlusionAmount"
        value: Number(principledMaterial.renderer.prop("occlusion_amount"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "alpha_mode"
        property: "alphaMode"
        value: Value3d.enumeration(principledMaterial.renderer.prop("alpha_mode"), {
            "default": PrincipledMaterial.Default,
            "mask": PrincipledMaterial.Mask,
            "blend": PrincipledMaterial.Blend,
            "opaque": PrincipledMaterial.Opaque
        }, PrincipledMaterial.Default)
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "alpha_cutoff"
        property: "alphaCutoff"
        value: Number(principledMaterial.renderer.prop("alpha_cutoff"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "point_size"
        property: "pointSize"
        value: Number(principledMaterial.renderer.prop("point_size"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "line_width"
        property: "lineWidth"
        value: Number(principledMaterial.renderer.prop("line_width"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "height_map"
        property: "heightMap"
        value: principledMaterial.renderer.sceneObject(principledMaterial.renderer.prop("height_map"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "height_channel"
        property: "heightChannel"
        value: Value3d.enumeration(principledMaterial.renderer.prop("height_channel"), {
            "r": PrincipledMaterial.R,
            "g": PrincipledMaterial.G,
            "b": PrincipledMaterial.B,
            "a": PrincipledMaterial.A
        }, PrincipledMaterial.R)
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "height_amount"
        property: "heightAmount"
        value: Number(principledMaterial.renderer.prop("height_amount"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "min_height_map_samples"
        property: "minHeightMapSamples"
        value: Number(principledMaterial.renderer.prop("min_height_map_samples"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "max_height_map_samples"
        property: "maxHeightMapSamples"
        value: Number(principledMaterial.renderer.prop("max_height_map_samples"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "clearcoat_amount"
        property: "clearcoatAmount"
        value: Number(principledMaterial.renderer.prop("clearcoat_amount"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "clearcoat_map"
        property: "clearcoatMap"
        value: principledMaterial.renderer.sceneObject(principledMaterial.renderer.prop("clearcoat_map"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "clearcoat_channel"
        property: "clearcoatChannel"
        value: Value3d.enumeration(principledMaterial.renderer.prop("clearcoat_channel"), {
            "r": PrincipledMaterial.R,
            "g": PrincipledMaterial.G,
            "b": PrincipledMaterial.B,
            "a": PrincipledMaterial.A
        }, PrincipledMaterial.R)
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "clearcoat_roughness_amount"
        property: "clearcoatRoughnessAmount"
        value: Number(principledMaterial.renderer.prop("clearcoat_roughness_amount"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "clearcoat_roughness_channel"
        property: "clearcoatRoughnessChannel"
        value: Value3d.enumeration(principledMaterial.renderer.prop("clearcoat_roughness_channel"), {
            "r": PrincipledMaterial.R,
            "g": PrincipledMaterial.G,
            "b": PrincipledMaterial.B,
            "a": PrincipledMaterial.A
        }, PrincipledMaterial.R)
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "clearcoat_roughness_map"
        property: "clearcoatRoughnessMap"
        value: principledMaterial.renderer.sceneObject(principledMaterial.renderer.prop("clearcoat_roughness_map"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "clearcoat_normal_map"
        property: "clearcoatNormalMap"
        value: principledMaterial.renderer.sceneObject(principledMaterial.renderer.prop("clearcoat_normal_map"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "clearcoat_normal_strength"
        property: "clearcoatNormalStrength"
        value: Number(principledMaterial.renderer.prop("clearcoat_normal_strength"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "transmission_factor"
        property: "transmissionFactor"
        value: Number(principledMaterial.renderer.prop("transmission_factor"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "transmission_map"
        property: "transmissionMap"
        value: principledMaterial.renderer.sceneObject(principledMaterial.renderer.prop("transmission_map"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "transmission_channel"
        property: "transmissionChannel"
        value: Value3d.enumeration(principledMaterial.renderer.prop("transmission_channel"), {
            "r": PrincipledMaterial.R,
            "g": PrincipledMaterial.G,
            "b": PrincipledMaterial.B,
            "a": PrincipledMaterial.A
        }, PrincipledMaterial.R)
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "thickness_factor"
        property: "thicknessFactor"
        value: Number(principledMaterial.renderer.prop("thickness_factor"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "thickness_map"
        property: "thicknessMap"
        value: principledMaterial.renderer.sceneObject(principledMaterial.renderer.prop("thickness_map"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "thickness_channel"
        property: "thicknessChannel"
        value: Value3d.enumeration(principledMaterial.renderer.prop("thickness_channel"), {
            "r": PrincipledMaterial.R,
            "g": PrincipledMaterial.G,
            "b": PrincipledMaterial.B,
            "a": PrincipledMaterial.A
        }, PrincipledMaterial.R)
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "attenuation_distance"
        property: "attenuationDistance"
        value: Number(principledMaterial.renderer.prop("attenuation_distance"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "attenuation_color"
        property: "attenuationColor"
        value: principledMaterial.renderer.prop("attenuation_color")
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "index_of_refraction"
        property: "indexOfRefraction"
        value: Number(principledMaterial.renderer.prop("index_of_refraction"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "vertex_colors_enabled"
        property: "vertexColorsEnabled"
        value: principledMaterial.renderer.prop("vertex_colors_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "fresnel_scale_bias_enabled"
        property: "fresnelScaleBiasEnabled"
        value: principledMaterial.renderer.prop("fresnel_scale_bias_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "fresnel_scale"
        property: "fresnelScale"
        value: Number(principledMaterial.renderer.prop("fresnel_scale"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "fresnel_bias"
        property: "fresnelBias"
        value: Number(principledMaterial.renderer.prop("fresnel_bias"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "fresnel_power"
        property: "fresnelPower"
        value: Number(principledMaterial.renderer.prop("fresnel_power"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "clearcoat_fresnel_scale_bias_enabled"
        property: "clearcoatFresnelScaleBiasEnabled"
        value: principledMaterial.renderer.prop("clearcoat_fresnel_scale_bias_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "clearcoat_fresnel_scale"
        property: "clearcoatFresnelScale"
        value: Number(principledMaterial.renderer.prop("clearcoat_fresnel_scale"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "clearcoat_fresnel_bias"
        property: "clearcoatFresnelBias"
        value: Number(principledMaterial.renderer.prop("clearcoat_fresnel_bias"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "clearcoat_fresnel_power"
        property: "clearcoatFresnelPower"
        value: Number(principledMaterial.renderer.prop("clearcoat_fresnel_power"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "vertex_colors_mask_enabled"
        property: "vertexColorsMaskEnabled"
        value: principledMaterial.renderer.prop("vertex_colors_mask_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "vertex_color_red_mask"
        property: "vertexColorRedMask"
        value: Value3d.enumeration(principledMaterial.renderer.prop("vertex_color_red_mask"), {
            "none": PrincipledMaterial.NoMask,
            "roughness": PrincipledMaterial.RoughnessMask,
            "normal_strength": PrincipledMaterial.NormalStrengthMask,
            "specular_amount": PrincipledMaterial.SpecularAmountMask,
            "clearcoat_amount": PrincipledMaterial.ClearcoatAmountMask,
            "clearcoat_roughness_amount": PrincipledMaterial.ClearcoatRoughnessAmountMask,
            "clearcoat_normal_strength": PrincipledMaterial.ClearcoatNormalStrengthMask,
            "height_amount": PrincipledMaterial.HeightAmountMask,
            "metalness": PrincipledMaterial.MetalnessMask,
            "occlusion_amount": PrincipledMaterial.OcclusionAmountMask,
            "thickness_factor": PrincipledMaterial.ThicknessFactorMask,
            "transmission_factor": PrincipledMaterial.TransmissionFactorMask
        }, PrincipledMaterial.NoMask)
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "vertex_color_green_mask"
        property: "vertexColorGreenMask"
        value: Value3d.enumeration(principledMaterial.renderer.prop("vertex_color_green_mask"), {
            "none": PrincipledMaterial.NoMask,
            "roughness": PrincipledMaterial.RoughnessMask,
            "normal_strength": PrincipledMaterial.NormalStrengthMask,
            "specular_amount": PrincipledMaterial.SpecularAmountMask,
            "clearcoat_amount": PrincipledMaterial.ClearcoatAmountMask,
            "clearcoat_roughness_amount": PrincipledMaterial.ClearcoatRoughnessAmountMask,
            "clearcoat_normal_strength": PrincipledMaterial.ClearcoatNormalStrengthMask,
            "height_amount": PrincipledMaterial.HeightAmountMask,
            "metalness": PrincipledMaterial.MetalnessMask,
            "occlusion_amount": PrincipledMaterial.OcclusionAmountMask,
            "thickness_factor": PrincipledMaterial.ThicknessFactorMask,
            "transmission_factor": PrincipledMaterial.TransmissionFactorMask
        }, PrincipledMaterial.NoMask)
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "vertex_color_blue_mask"
        property: "vertexColorBlueMask"
        value: Value3d.enumeration(principledMaterial.renderer.prop("vertex_color_blue_mask"), {
            "none": PrincipledMaterial.NoMask,
            "roughness": PrincipledMaterial.RoughnessMask,
            "normal_strength": PrincipledMaterial.NormalStrengthMask,
            "specular_amount": PrincipledMaterial.SpecularAmountMask,
            "clearcoat_amount": PrincipledMaterial.ClearcoatAmountMask,
            "clearcoat_roughness_amount": PrincipledMaterial.ClearcoatRoughnessAmountMask,
            "clearcoat_normal_strength": PrincipledMaterial.ClearcoatNormalStrengthMask,
            "height_amount": PrincipledMaterial.HeightAmountMask,
            "metalness": PrincipledMaterial.MetalnessMask,
            "occlusion_amount": PrincipledMaterial.OcclusionAmountMask,
            "thickness_factor": PrincipledMaterial.ThicknessFactorMask,
            "transmission_factor": PrincipledMaterial.TransmissionFactorMask
        }, PrincipledMaterial.NoMask)
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "vertex_color_alpha_mask"
        property: "vertexColorAlphaMask"
        value: Value3d.enumeration(principledMaterial.renderer.prop("vertex_color_alpha_mask"), {
            "none": PrincipledMaterial.NoMask,
            "roughness": PrincipledMaterial.RoughnessMask,
            "normal_strength": PrincipledMaterial.NormalStrengthMask,
            "specular_amount": PrincipledMaterial.SpecularAmountMask,
            "clearcoat_amount": PrincipledMaterial.ClearcoatAmountMask,
            "clearcoat_roughness_amount": PrincipledMaterial.ClearcoatRoughnessAmountMask,
            "clearcoat_normal_strength": PrincipledMaterial.ClearcoatNormalStrengthMask,
            "height_amount": PrincipledMaterial.HeightAmountMask,
            "metalness": PrincipledMaterial.MetalnessMask,
            "occlusion_amount": PrincipledMaterial.OcclusionAmountMask,
            "thickness_factor": PrincipledMaterial.ThicknessFactorMask,
            "transmission_factor": PrincipledMaterial.TransmissionFactorMask
        }, PrincipledMaterial.NoMask)
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "light_probe"
        property: "lightProbe"
        value: principledMaterial.renderer.sceneObject(principledMaterial.renderer.prop("light_probe"))
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "cull_mode"
        property: "cullMode"
        value: Value3d.enumeration(principledMaterial.renderer.prop("cull_mode"), {
            "back": PrincipledMaterial.BackFaceCulling,
            "front": PrincipledMaterial.FrontFaceCulling,
            "none": PrincipledMaterial.NoCulling
        }, PrincipledMaterial.BackFaceCulling)
    }

    Support.Prop3dBinding {
        renderer: principledMaterial.renderer
        target: principledMaterial
        name: "depth_draw_mode"
        property: "depthDrawMode"
        value: Value3d.enumeration(principledMaterial.renderer.prop("depth_draw_mode"), {
            "opaque_only": PrincipledMaterial.OpaqueOnlyDepthDraw,
            "always": PrincipledMaterial.AlwaysDepthDraw,
            "never": PrincipledMaterial.NeverDepthDraw,
            "opaque_prepass": PrincipledMaterial.OpaquePrePassDepthDraw
        }, PrincipledMaterial.OpaqueOnlyDepthDraw)
    }
}
