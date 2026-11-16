import QtQuick
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// The specular-glossiness physically based material, for assets authored
// against that workflow rather than metal-roughness.
SpecularGlossyMaterial {
    id: specularGlossyMaterial

    required property var renderer

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "lighting"
        property: "lighting"
        value: Value3d.enumeration(specularGlossyMaterial.renderer.prop("lighting"), {
            "none": SpecularGlossyMaterial.NoLighting,
            "fragment": SpecularGlossyMaterial.FragmentLighting
        }, SpecularGlossyMaterial.NoLighting)
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "blend_mode"
        property: "blendMode"
        value: Value3d.enumeration(specularGlossyMaterial.renderer.prop("blend_mode"), {
            "source_over": SpecularGlossyMaterial.SourceOver,
            "screen": SpecularGlossyMaterial.Screen,
            "multiply": SpecularGlossyMaterial.Multiply
        }, SpecularGlossyMaterial.SourceOver)
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "albedo_color"
        property: "albedoColor"
        value: specularGlossyMaterial.renderer.prop("albedo_color")
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "albedo_map"
        property: "albedoMap"
        value: specularGlossyMaterial.renderer.sceneObject(specularGlossyMaterial.renderer.prop("albedo_map"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "albedo_single_channel_enabled"
        property: "albedoSingleChannelEnabled"
        value: specularGlossyMaterial.renderer.prop("albedo_single_channel_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "albedo_channel"
        property: "albedoChannel"
        value: Value3d.enumeration(specularGlossyMaterial.renderer.prop("albedo_channel"), {
            "r": SpecularGlossyMaterial.R,
            "g": SpecularGlossyMaterial.G,
            "b": SpecularGlossyMaterial.B,
            "a": SpecularGlossyMaterial.A
        }, SpecularGlossyMaterial.R)
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "specular_color"
        property: "specularColor"
        value: specularGlossyMaterial.renderer.prop("specular_color")
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "specular_map"
        property: "specularMap"
        value: specularGlossyMaterial.renderer.sceneObject(specularGlossyMaterial.renderer.prop("specular_map"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "specular_single_channel_enabled"
        property: "specularSingleChannelEnabled"
        value: specularGlossyMaterial.renderer.prop("specular_single_channel_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "specular_channel"
        property: "specularChannel"
        value: Value3d.enumeration(specularGlossyMaterial.renderer.prop("specular_channel"), {
            "r": SpecularGlossyMaterial.R,
            "g": SpecularGlossyMaterial.G,
            "b": SpecularGlossyMaterial.B,
            "a": SpecularGlossyMaterial.A
        }, SpecularGlossyMaterial.R)
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "glossiness"
        property: "glossiness"
        value: Number(specularGlossyMaterial.renderer.prop("glossiness"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "glossiness_map"
        property: "glossinessMap"
        value: specularGlossyMaterial.renderer.sceneObject(specularGlossyMaterial.renderer.prop("glossiness_map"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "glossiness_channel"
        property: "glossinessChannel"
        value: Value3d.enumeration(specularGlossyMaterial.renderer.prop("glossiness_channel"), {
            "r": SpecularGlossyMaterial.R,
            "g": SpecularGlossyMaterial.G,
            "b": SpecularGlossyMaterial.B,
            "a": SpecularGlossyMaterial.A
        }, SpecularGlossyMaterial.R)
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "emissive_factor"
        property: "emissiveFactor"
        value: Value3d.vector3d(specularGlossyMaterial.renderer.prop("emissive_factor"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "emissive_map"
        property: "emissiveMap"
        value: specularGlossyMaterial.renderer.sceneObject(specularGlossyMaterial.renderer.prop("emissive_map"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "emissive_single_channel_enabled"
        property: "emissiveSingleChannelEnabled"
        value: specularGlossyMaterial.renderer.prop("emissive_single_channel_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "emissive_channel"
        property: "emissiveChannel"
        value: Value3d.enumeration(specularGlossyMaterial.renderer.prop("emissive_channel"), {
            "r": SpecularGlossyMaterial.R,
            "g": SpecularGlossyMaterial.G,
            "b": SpecularGlossyMaterial.B,
            "a": SpecularGlossyMaterial.A
        }, SpecularGlossyMaterial.R)
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "invert_opacity_map_value"
        property: "invertOpacityMapValue"
        value: specularGlossyMaterial.renderer.prop("invert_opacity_map_value") === true
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "opacity"
        property: "opacity"
        value: Number(specularGlossyMaterial.renderer.prop("opacity"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "opacity_map"
        property: "opacityMap"
        value: specularGlossyMaterial.renderer.sceneObject(specularGlossyMaterial.renderer.prop("opacity_map"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "opacity_channel"
        property: "opacityChannel"
        value: Value3d.enumeration(specularGlossyMaterial.renderer.prop("opacity_channel"), {
            "r": SpecularGlossyMaterial.R,
            "g": SpecularGlossyMaterial.G,
            "b": SpecularGlossyMaterial.B,
            "a": SpecularGlossyMaterial.A
        }, SpecularGlossyMaterial.R)
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "normal_map"
        property: "normalMap"
        value: specularGlossyMaterial.renderer.sceneObject(specularGlossyMaterial.renderer.prop("normal_map"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "normal_strength"
        property: "normalStrength"
        value: Number(specularGlossyMaterial.renderer.prop("normal_strength"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "occlusion_map"
        property: "occlusionMap"
        value: specularGlossyMaterial.renderer.sceneObject(specularGlossyMaterial.renderer.prop("occlusion_map"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "occlusion_channel"
        property: "occlusionChannel"
        value: Value3d.enumeration(specularGlossyMaterial.renderer.prop("occlusion_channel"), {
            "r": SpecularGlossyMaterial.R,
            "g": SpecularGlossyMaterial.G,
            "b": SpecularGlossyMaterial.B,
            "a": SpecularGlossyMaterial.A
        }, SpecularGlossyMaterial.R)
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "occlusion_amount"
        property: "occlusionAmount"
        value: Number(specularGlossyMaterial.renderer.prop("occlusion_amount"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "alpha_mode"
        property: "alphaMode"
        value: Value3d.enumeration(specularGlossyMaterial.renderer.prop("alpha_mode"), {
            "default": SpecularGlossyMaterial.Default,
            "mask": SpecularGlossyMaterial.Mask,
            "blend": SpecularGlossyMaterial.Blend,
            "opaque": SpecularGlossyMaterial.Opaque
        }, SpecularGlossyMaterial.Default)
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "alpha_cutoff"
        property: "alphaCutoff"
        value: Number(specularGlossyMaterial.renderer.prop("alpha_cutoff"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "point_size"
        property: "pointSize"
        value: Number(specularGlossyMaterial.renderer.prop("point_size"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "line_width"
        property: "lineWidth"
        value: Number(specularGlossyMaterial.renderer.prop("line_width"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "height_map"
        property: "heightMap"
        value: specularGlossyMaterial.renderer.sceneObject(specularGlossyMaterial.renderer.prop("height_map"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "height_channel"
        property: "heightChannel"
        value: Value3d.enumeration(specularGlossyMaterial.renderer.prop("height_channel"), {
            "r": SpecularGlossyMaterial.R,
            "g": SpecularGlossyMaterial.G,
            "b": SpecularGlossyMaterial.B,
            "a": SpecularGlossyMaterial.A
        }, SpecularGlossyMaterial.R)
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "height_amount"
        property: "heightAmount"
        value: Number(specularGlossyMaterial.renderer.prop("height_amount"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "min_height_map_samples"
        property: "minHeightMapSamples"
        value: Number(specularGlossyMaterial.renderer.prop("min_height_map_samples"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "max_height_map_samples"
        property: "maxHeightMapSamples"
        value: Number(specularGlossyMaterial.renderer.prop("max_height_map_samples"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "clearcoat_amount"
        property: "clearcoatAmount"
        value: Number(specularGlossyMaterial.renderer.prop("clearcoat_amount"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "clearcoat_map"
        property: "clearcoatMap"
        value: specularGlossyMaterial.renderer.sceneObject(specularGlossyMaterial.renderer.prop("clearcoat_map"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "clearcoat_channel"
        property: "clearcoatChannel"
        value: Value3d.enumeration(specularGlossyMaterial.renderer.prop("clearcoat_channel"), {
            "r": SpecularGlossyMaterial.R,
            "g": SpecularGlossyMaterial.G,
            "b": SpecularGlossyMaterial.B,
            "a": SpecularGlossyMaterial.A
        }, SpecularGlossyMaterial.R)
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "clearcoat_roughness_amount"
        property: "clearcoatRoughnessAmount"
        value: Number(specularGlossyMaterial.renderer.prop("clearcoat_roughness_amount"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "clearcoat_roughness_channel"
        property: "clearcoatRoughnessChannel"
        value: Value3d.enumeration(specularGlossyMaterial.renderer.prop("clearcoat_roughness_channel"), {
            "r": SpecularGlossyMaterial.R,
            "g": SpecularGlossyMaterial.G,
            "b": SpecularGlossyMaterial.B,
            "a": SpecularGlossyMaterial.A
        }, SpecularGlossyMaterial.R)
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "clearcoat_roughness_map"
        property: "clearcoatRoughnessMap"
        value: specularGlossyMaterial.renderer.sceneObject(specularGlossyMaterial.renderer.prop("clearcoat_roughness_map"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "clearcoat_normal_map"
        property: "clearcoatNormalMap"
        value: specularGlossyMaterial.renderer.sceneObject(specularGlossyMaterial.renderer.prop("clearcoat_normal_map"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "clearcoat_normal_strength"
        property: "clearcoatNormalStrength"
        value: Number(specularGlossyMaterial.renderer.prop("clearcoat_normal_strength"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "transmission_factor"
        property: "transmissionFactor"
        value: Number(specularGlossyMaterial.renderer.prop("transmission_factor"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "transmission_map"
        property: "transmissionMap"
        value: specularGlossyMaterial.renderer.sceneObject(specularGlossyMaterial.renderer.prop("transmission_map"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "transmission_channel"
        property: "transmissionChannel"
        value: Value3d.enumeration(specularGlossyMaterial.renderer.prop("transmission_channel"), {
            "r": SpecularGlossyMaterial.R,
            "g": SpecularGlossyMaterial.G,
            "b": SpecularGlossyMaterial.B,
            "a": SpecularGlossyMaterial.A
        }, SpecularGlossyMaterial.R)
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "thickness_factor"
        property: "thicknessFactor"
        value: Number(specularGlossyMaterial.renderer.prop("thickness_factor"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "thickness_map"
        property: "thicknessMap"
        value: specularGlossyMaterial.renderer.sceneObject(specularGlossyMaterial.renderer.prop("thickness_map"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "thickness_channel"
        property: "thicknessChannel"
        value: Value3d.enumeration(specularGlossyMaterial.renderer.prop("thickness_channel"), {
            "r": SpecularGlossyMaterial.R,
            "g": SpecularGlossyMaterial.G,
            "b": SpecularGlossyMaterial.B,
            "a": SpecularGlossyMaterial.A
        }, SpecularGlossyMaterial.R)
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "attenuation_distance"
        property: "attenuationDistance"
        value: Number(specularGlossyMaterial.renderer.prop("attenuation_distance"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "attenuation_color"
        property: "attenuationColor"
        value: specularGlossyMaterial.renderer.prop("attenuation_color")
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "vertex_colors_enabled"
        property: "vertexColorsEnabled"
        value: specularGlossyMaterial.renderer.prop("vertex_colors_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "fresnel_scale_bias_enabled"
        property: "fresnelScaleBiasEnabled"
        value: specularGlossyMaterial.renderer.prop("fresnel_scale_bias_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "fresnel_scale"
        property: "fresnelScale"
        value: Number(specularGlossyMaterial.renderer.prop("fresnel_scale"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "fresnel_bias"
        property: "fresnelBias"
        value: Number(specularGlossyMaterial.renderer.prop("fresnel_bias"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "fresnel_power"
        property: "fresnelPower"
        value: Number(specularGlossyMaterial.renderer.prop("fresnel_power"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "clearcoat_fresnel_scale_bias_enabled"
        property: "clearcoatFresnelScaleBiasEnabled"
        value: specularGlossyMaterial.renderer.prop("clearcoat_fresnel_scale_bias_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "clearcoat_fresnel_scale"
        property: "clearcoatFresnelScale"
        value: Number(specularGlossyMaterial.renderer.prop("clearcoat_fresnel_scale"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "clearcoat_fresnel_bias"
        property: "clearcoatFresnelBias"
        value: Number(specularGlossyMaterial.renderer.prop("clearcoat_fresnel_bias"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "clearcoat_fresnel_power"
        property: "clearcoatFresnelPower"
        value: Number(specularGlossyMaterial.renderer.prop("clearcoat_fresnel_power"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "vertex_colors_mask_enabled"
        property: "vertexColorsMaskEnabled"
        value: specularGlossyMaterial.renderer.prop("vertex_colors_mask_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "vertex_color_red_mask"
        property: "vertexColorRedMask"
        value: Value3d.enumeration(specularGlossyMaterial.renderer.prop("vertex_color_red_mask"), {
            "none": SpecularGlossyMaterial.NoMask,
            "glossiness": SpecularGlossyMaterial.GlossinessMask,
            "normal_strength": SpecularGlossyMaterial.NormalStrengthMask,
            "clearcoat_amount": SpecularGlossyMaterial.ClearcoatAmountMask,
            "clearcoat_roughness_amount": SpecularGlossyMaterial.ClearcoatRoughnessAmountMask,
            "clearcoat_normal_strength": SpecularGlossyMaterial.ClearcoatNormalStrengthMask,
            "height_amount": SpecularGlossyMaterial.HeightAmountMask,
            "occlusion_amount": SpecularGlossyMaterial.OcclusionAmountMask,
            "thickness_factor": SpecularGlossyMaterial.ThicknessFactorMask,
            "transmission_factor": SpecularGlossyMaterial.TransmissionFactorMask
        }, SpecularGlossyMaterial.NoMask)
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "vertex_color_green_mask"
        property: "vertexColorGreenMask"
        value: Value3d.enumeration(specularGlossyMaterial.renderer.prop("vertex_color_green_mask"), {
            "none": SpecularGlossyMaterial.NoMask,
            "glossiness": SpecularGlossyMaterial.GlossinessMask,
            "normal_strength": SpecularGlossyMaterial.NormalStrengthMask,
            "clearcoat_amount": SpecularGlossyMaterial.ClearcoatAmountMask,
            "clearcoat_roughness_amount": SpecularGlossyMaterial.ClearcoatRoughnessAmountMask,
            "clearcoat_normal_strength": SpecularGlossyMaterial.ClearcoatNormalStrengthMask,
            "height_amount": SpecularGlossyMaterial.HeightAmountMask,
            "occlusion_amount": SpecularGlossyMaterial.OcclusionAmountMask,
            "thickness_factor": SpecularGlossyMaterial.ThicknessFactorMask,
            "transmission_factor": SpecularGlossyMaterial.TransmissionFactorMask
        }, SpecularGlossyMaterial.NoMask)
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "vertex_color_blue_mask"
        property: "vertexColorBlueMask"
        value: Value3d.enumeration(specularGlossyMaterial.renderer.prop("vertex_color_blue_mask"), {
            "none": SpecularGlossyMaterial.NoMask,
            "glossiness": SpecularGlossyMaterial.GlossinessMask,
            "normal_strength": SpecularGlossyMaterial.NormalStrengthMask,
            "clearcoat_amount": SpecularGlossyMaterial.ClearcoatAmountMask,
            "clearcoat_roughness_amount": SpecularGlossyMaterial.ClearcoatRoughnessAmountMask,
            "clearcoat_normal_strength": SpecularGlossyMaterial.ClearcoatNormalStrengthMask,
            "height_amount": SpecularGlossyMaterial.HeightAmountMask,
            "occlusion_amount": SpecularGlossyMaterial.OcclusionAmountMask,
            "thickness_factor": SpecularGlossyMaterial.ThicknessFactorMask,
            "transmission_factor": SpecularGlossyMaterial.TransmissionFactorMask
        }, SpecularGlossyMaterial.NoMask)
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "vertex_color_alpha_mask"
        property: "vertexColorAlphaMask"
        value: Value3d.enumeration(specularGlossyMaterial.renderer.prop("vertex_color_alpha_mask"), {
            "none": SpecularGlossyMaterial.NoMask,
            "glossiness": SpecularGlossyMaterial.GlossinessMask,
            "normal_strength": SpecularGlossyMaterial.NormalStrengthMask,
            "clearcoat_amount": SpecularGlossyMaterial.ClearcoatAmountMask,
            "clearcoat_roughness_amount": SpecularGlossyMaterial.ClearcoatRoughnessAmountMask,
            "clearcoat_normal_strength": SpecularGlossyMaterial.ClearcoatNormalStrengthMask,
            "height_amount": SpecularGlossyMaterial.HeightAmountMask,
            "occlusion_amount": SpecularGlossyMaterial.OcclusionAmountMask,
            "thickness_factor": SpecularGlossyMaterial.ThicknessFactorMask,
            "transmission_factor": SpecularGlossyMaterial.TransmissionFactorMask
        }, SpecularGlossyMaterial.NoMask)
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "light_probe"
        property: "lightProbe"
        value: specularGlossyMaterial.renderer.sceneObject(specularGlossyMaterial.renderer.prop("light_probe"))
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "cull_mode"
        property: "cullMode"
        value: Value3d.enumeration(specularGlossyMaterial.renderer.prop("cull_mode"), {
            "back": SpecularGlossyMaterial.BackFaceCulling,
            "front": SpecularGlossyMaterial.FrontFaceCulling,
            "none": SpecularGlossyMaterial.NoCulling
        }, SpecularGlossyMaterial.BackFaceCulling)
    }

    Support.Prop3dBinding {
        renderer: specularGlossyMaterial.renderer
        target: specularGlossyMaterial
        name: "depth_draw_mode"
        property: "depthDrawMode"
        value: Value3d.enumeration(specularGlossyMaterial.renderer.prop("depth_draw_mode"), {
            "opaque_only": SpecularGlossyMaterial.OpaqueOnlyDepthDraw,
            "always": SpecularGlossyMaterial.AlwaysDepthDraw,
            "never": SpecularGlossyMaterial.NeverDepthDraw,
            "opaque_prepass": SpecularGlossyMaterial.OpaquePrePassDepthDraw
        }, SpecularGlossyMaterial.OpaqueOnlyDepthDraw)
    }
}
