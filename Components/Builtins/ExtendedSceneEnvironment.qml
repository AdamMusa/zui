import QtQuick
import QtQuick3D.Helpers
import "Support" as Support
import "Support/Value3d.js" as Value3d
import "Support/Scene3dTypes.js" as Scene3dTypes

// A scene environment with Qt's built-in post-processing chain: depth of
// field, glow, vignette, lens flare, a colour lookup table and the
// tonemapping adjustments, all applied in one pass.
ExtendedSceneEnvironment {
    id: extendedSceneEnvironment

    required property var renderer

    lightProbe: renderer.childObjectOrReference(["texture_3d", "cube_map_texture", "procedural_sky_texture_data"], "light_probe")
    skyBoxCubeMap: renderer.childObjectOrReference(["cube_map_texture"], "skybox_cube_map")
    fog: renderer.childObjectOrReference(["fog"], "fog")
    lightmapper: renderer.childObjectOrReference(["lightmapper"], "lightmapper")
    debugSettings: renderer.childObjectOrReference(["debug_settings"], "debug_settings")
    effects: renderer.childObjectsAndReferences(Scene3dTypes.effects, "effects")

    // Qt takes the scissor rectangle as a QRect; Ruby declares it as
    // [x, y, width, height].
    scissorRect: Qt.rect(Number(renderer.prop("scissor_rect", [0, 0, 0, 0])[0]), Number(renderer.prop("scissor_rect", [0, 0, 0, 0])[1]), Number(renderer.prop("scissor_rect", [0, 0, 0, 0])[2]), Number(renderer.prop("scissor_rect", [0, 0, 0, 0])[3]))

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "antialiasing_mode"
        property: "antialiasingMode"
        value: Value3d.enumeration(extendedSceneEnvironment.renderer.prop("antialiasing_mode"), {
            "none": ExtendedSceneEnvironment.NoAA,
            "ssaa": ExtendedSceneEnvironment.SSAA,
            "msaa": ExtendedSceneEnvironment.MSAA,
            "progressive": ExtendedSceneEnvironment.ProgressiveAA
        }, ExtendedSceneEnvironment.NoAA)
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "antialiasing_quality"
        property: "antialiasingQuality"
        value: Value3d.enumeration(extendedSceneEnvironment.renderer.prop("antialiasing_quality"), {
            "medium": ExtendedSceneEnvironment.Medium,
            "high": ExtendedSceneEnvironment.High,
            "very_high": ExtendedSceneEnvironment.VeryHigh
        }, ExtendedSceneEnvironment.Medium)
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "temporal_aa_enabled"
        property: "temporalAAEnabled"
        value: extendedSceneEnvironment.renderer.prop("temporal_aa_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "temporal_aa_strength"
        property: "temporalAAStrength"
        value: Number(extendedSceneEnvironment.renderer.prop("temporal_aa_strength"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "background_mode"
        property: "backgroundMode"
        value: Value3d.enumeration(extendedSceneEnvironment.renderer.prop("background_mode"), {
            "transparent": ExtendedSceneEnvironment.Transparent,
            "unspecified": ExtendedSceneEnvironment.Unspecified,
            "color": ExtendedSceneEnvironment.Color,
            "skybox": ExtendedSceneEnvironment.SkyBox,
            "skybox_cube_map": ExtendedSceneEnvironment.SkyBoxCubeMap
        }, ExtendedSceneEnvironment.Transparent)
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "clear_color"
        property: "clearColor"
        value: extendedSceneEnvironment.renderer.prop("clear_color")
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "depth_test_enabled"
        property: "depthTestEnabled"
        value: extendedSceneEnvironment.renderer.prop("depth_test_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "depth_pre_pass_enabled"
        property: "depthPrePassEnabled"
        value: extendedSceneEnvironment.renderer.prop("depth_pre_pass_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "ao_strength"
        property: "aoStrength"
        value: Number(extendedSceneEnvironment.renderer.prop("ao_strength"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "ao_distance"
        property: "aoDistance"
        value: Number(extendedSceneEnvironment.renderer.prop("ao_distance"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "ao_softness"
        property: "aoSoftness"
        value: Number(extendedSceneEnvironment.renderer.prop("ao_softness"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "ao_dither"
        property: "aoDither"
        value: extendedSceneEnvironment.renderer.prop("ao_dither") === true
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "ao_sample_rate"
        property: "aoSampleRate"
        value: Number(extendedSceneEnvironment.renderer.prop("ao_sample_rate"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "ao_bias"
        property: "aoBias"
        value: Number(extendedSceneEnvironment.renderer.prop("ao_bias"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "ao_enabled"
        property: "aoEnabled"
        value: extendedSceneEnvironment.renderer.prop("ao_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "probe_exposure"
        property: "probeExposure"
        value: Number(extendedSceneEnvironment.renderer.prop("probe_exposure"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "probe_horizon"
        property: "probeHorizon"
        value: Number(extendedSceneEnvironment.renderer.prop("probe_horizon"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "probe_orientation"
        property: "probeOrientation"
        value: Value3d.vector3d(extendedSceneEnvironment.renderer.prop("probe_orientation"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "tonemap_mode"
        property: "tonemapMode"
        value: Value3d.enumeration(extendedSceneEnvironment.renderer.prop("tonemap_mode"), {
            "none": ExtendedSceneEnvironment.TonemapModeNone,
            "linear": ExtendedSceneEnvironment.TonemapModeLinear,
            "aces": ExtendedSceneEnvironment.TonemapModeAces,
            "hejl_dawson": ExtendedSceneEnvironment.TonemapModeHejlDawson,
            "filmic": ExtendedSceneEnvironment.TonemapModeFilmic
        }, ExtendedSceneEnvironment.TonemapModeNone)
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "skybox_blur_amount"
        property: "skyboxBlurAmount"
        value: Number(extendedSceneEnvironment.renderer.prop("skybox_blur_amount"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "specular_aa_enabled"
        property: "specularAAEnabled"
        value: extendedSceneEnvironment.renderer.prop("specular_aa_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "depth_of_field_enabled"
        property: "depthOfFieldEnabled"
        value: extendedSceneEnvironment.renderer.prop("depth_of_field_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "depth_of_field_focus_distance"
        property: "depthOfFieldFocusDistance"
        value: Number(extendedSceneEnvironment.renderer.prop("depth_of_field_focus_distance"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "depth_of_field_focus_range"
        property: "depthOfFieldFocusRange"
        value: Number(extendedSceneEnvironment.renderer.prop("depth_of_field_focus_range"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "depth_of_field_blur_amount"
        property: "depthOfFieldBlurAmount"
        value: Number(extendedSceneEnvironment.renderer.prop("depth_of_field_blur_amount"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "exposure"
        property: "exposure"
        value: Number(extendedSceneEnvironment.renderer.prop("exposure"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "white_point"
        property: "whitePoint"
        value: Number(extendedSceneEnvironment.renderer.prop("white_point"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "dithering_enabled"
        property: "ditheringEnabled"
        value: extendedSceneEnvironment.renderer.prop("dithering_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "sharpness_amount"
        property: "sharpnessAmount"
        value: Number(extendedSceneEnvironment.renderer.prop("sharpness_amount"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "fxaa_enabled"
        property: "fxaaEnabled"
        value: extendedSceneEnvironment.renderer.prop("fxaa_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "color_adjustments_enabled"
        property: "colorAdjustmentsEnabled"
        value: extendedSceneEnvironment.renderer.prop("color_adjustments_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "adjustment_brightness"
        property: "adjustmentBrightness"
        value: Number(extendedSceneEnvironment.renderer.prop("adjustment_brightness"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "adjustment_contrast"
        property: "adjustmentContrast"
        value: Number(extendedSceneEnvironment.renderer.prop("adjustment_contrast"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "adjustment_saturation"
        property: "adjustmentSaturation"
        value: Number(extendedSceneEnvironment.renderer.prop("adjustment_saturation"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "lut_enabled"
        property: "lutEnabled"
        value: extendedSceneEnvironment.renderer.prop("lut_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "lut_size"
        property: "lutSize"
        value: Number(extendedSceneEnvironment.renderer.prop("lut_size"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "lut_filter_alpha"
        property: "lutFilterAlpha"
        value: Number(extendedSceneEnvironment.renderer.prop("lut_filter_alpha"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "lut_texture"
        property: "lutTexture"
        value: extendedSceneEnvironment.renderer.sceneObject(extendedSceneEnvironment.renderer.prop("lut_texture"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "glow_enabled"
        property: "glowEnabled"
        value: extendedSceneEnvironment.renderer.prop("glow_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "glow_quality_high"
        property: "glowQualityHigh"
        value: extendedSceneEnvironment.renderer.prop("glow_quality_high") === true
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "glow_use_bicubic_upscale"
        property: "glowUseBicubicUpscale"
        value: extendedSceneEnvironment.renderer.prop("glow_use_bicubic_upscale") === true
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "glow_strength"
        property: "glowStrength"
        value: Number(extendedSceneEnvironment.renderer.prop("glow_strength"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "glow_intensity"
        property: "glowIntensity"
        value: Number(extendedSceneEnvironment.renderer.prop("glow_intensity"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "glow_bloom"
        property: "glowBloom"
        value: Number(extendedSceneEnvironment.renderer.prop("glow_bloom"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "glow_blend_mode"
        property: "glowBlendMode"
        value: Value3d.enumeration(extendedSceneEnvironment.renderer.prop("glow_blend_mode"), {
            "additive": ExtendedSceneEnvironment.Additive,
            "screen": ExtendedSceneEnvironment.Screen,
            "soft_light": ExtendedSceneEnvironment.SoftLight,
            "replace": ExtendedSceneEnvironment.Replace
        }, ExtendedSceneEnvironment.Additive)
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "glow_hdr_maximum_value"
        property: "glowHDRMaximumValue"
        value: Number(extendedSceneEnvironment.renderer.prop("glow_hdr_maximum_value"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "glow_hdr_scale"
        property: "glowHDRScale"
        value: Number(extendedSceneEnvironment.renderer.prop("glow_hdr_scale"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "glow_hdr_minimum_value"
        property: "glowHDRMinimumValue"
        value: Number(extendedSceneEnvironment.renderer.prop("glow_hdr_minimum_value"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "glow_level"
        property: "glowLevel"
        value: Value3d.flags(extendedSceneEnvironment.renderer.prop("glow_level"), {
            "one": ExtendedSceneEnvironment.One,
            "two": ExtendedSceneEnvironment.Two,
            "three": ExtendedSceneEnvironment.Three,
            "four": ExtendedSceneEnvironment.Four,
            "five": ExtendedSceneEnvironment.Five,
            "six": ExtendedSceneEnvironment.Six,
            "seven": ExtendedSceneEnvironment.Seven
        }, ExtendedSceneEnvironment.One)
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "vignette_enabled"
        property: "vignetteEnabled"
        value: extendedSceneEnvironment.renderer.prop("vignette_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "vignette_strength"
        property: "vignetteStrength"
        value: Number(extendedSceneEnvironment.renderer.prop("vignette_strength"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "vignette_color"
        property: "vignetteColor"
        value: extendedSceneEnvironment.renderer.prop("vignette_color")
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "vignette_radius"
        property: "vignetteRadius"
        value: Number(extendedSceneEnvironment.renderer.prop("vignette_radius"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "lens_flare_enabled"
        property: "lensFlareEnabled"
        value: extendedSceneEnvironment.renderer.prop("lens_flare_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "lens_flare_bloom_scale"
        property: "lensFlareBloomScale"
        value: Number(extendedSceneEnvironment.renderer.prop("lens_flare_bloom_scale"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "lens_flare_bloom_bias"
        property: "lensFlareBloomBias"
        value: Number(extendedSceneEnvironment.renderer.prop("lens_flare_bloom_bias"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "lens_flare_ghost_dispersal"
        property: "lensFlareGhostDispersal"
        value: Number(extendedSceneEnvironment.renderer.prop("lens_flare_ghost_dispersal"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "lens_flare_ghost_count"
        property: "lensFlareGhostCount"
        value: Number(extendedSceneEnvironment.renderer.prop("lens_flare_ghost_count"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "lens_flare_halo_width"
        property: "lensFlareHaloWidth"
        value: Number(extendedSceneEnvironment.renderer.prop("lens_flare_halo_width"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "lens_flare_stretch_to_aspect"
        property: "lensFlareStretchToAspect"
        value: Number(extendedSceneEnvironment.renderer.prop("lens_flare_stretch_to_aspect"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "lens_flare_distortion"
        property: "lensFlareDistortion"
        value: Number(extendedSceneEnvironment.renderer.prop("lens_flare_distortion"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "lens_flare_blur_amount"
        property: "lensFlareBlurAmount"
        value: Number(extendedSceneEnvironment.renderer.prop("lens_flare_blur_amount"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "lens_flare_apply_dirt_texture"
        property: "lensFlareApplyDirtTexture"
        value: extendedSceneEnvironment.renderer.prop("lens_flare_apply_dirt_texture") === true
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "lens_flare_apply_starburst_texture"
        property: "lensFlareApplyStarburstTexture"
        value: extendedSceneEnvironment.renderer.prop("lens_flare_apply_starburst_texture") === true
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "lens_flare_camera_direction"
        property: "lensFlareCameraDirection"
        value: Value3d.vector3d(extendedSceneEnvironment.renderer.prop("lens_flare_camera_direction"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "lens_flare_lens_color_texture"
        property: "lensFlareLensColorTexture"
        value: extendedSceneEnvironment.renderer.sceneObject(extendedSceneEnvironment.renderer.prop("lens_flare_lens_color_texture"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "lens_flare_lens_dirt_texture"
        property: "lensFlareLensDirtTexture"
        value: extendedSceneEnvironment.renderer.sceneObject(extendedSceneEnvironment.renderer.prop("lens_flare_lens_dirt_texture"))
    }

    Support.Prop3dBinding {
        renderer: extendedSceneEnvironment.renderer
        target: extendedSceneEnvironment
        name: "lens_flare_lens_starburst_texture"
        property: "lensFlareLensStarburstTexture"
        value: extendedSceneEnvironment.renderer.sceneObject(extendedSceneEnvironment.renderer.prop("lens_flare_lens_starburst_texture"))
    }
}
