import QtQuick
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d
import "Support/Scene3dTypes.js" as Scene3dTypes

// How a view_3d renders the space around its geometry: the background,
// antialiasing, ambient occlusion, image based lighting, tonemapping and
// the fog, lightmapper and debug settings declared inside it.
SceneEnvironment {
    id: sceneEnvironment

    required property var renderer

    lightProbe: renderer.childObjectOrReference(Scene3dTypes.textures, "light_probe")
    skyBoxCubeMap: renderer.childObjectOrReference(["cube_map_texture"], "skybox_cube_map")
    fog: renderer.childObjectOrReference(["fog"], "fog")
    lightmapper: renderer.childObjectOrReference(["lightmapper"], "lightmapper")
    debugSettings: renderer.childObjectOrReference(["debug_settings"], "debug_settings")
    effects: renderer.childObjectsAndReferences(Scene3dTypes.effects, "effects")

    // Qt takes the scissor rectangle as a QRect; Ruby declares it as
    // [x, y, width, height].
    scissorRect: Qt.rect(Number(renderer.prop("scissor_rect", [0, 0, 0, 0])[0]), Number(renderer.prop("scissor_rect", [0, 0, 0, 0])[1]), Number(renderer.prop("scissor_rect", [0, 0, 0, 0])[2]), Number(renderer.prop("scissor_rect", [0, 0, 0, 0])[3]))

    Support.Prop3dBinding {
        renderer: sceneEnvironment.renderer
        target: sceneEnvironment
        name: "antialiasing_mode"
        property: "antialiasingMode"
        value: Value3d.enumeration(sceneEnvironment.renderer.prop("antialiasing_mode"), {
            "none": SceneEnvironment.NoAA,
            "ssaa": SceneEnvironment.SSAA,
            "msaa": SceneEnvironment.MSAA,
            "progressive": SceneEnvironment.ProgressiveAA
        }, SceneEnvironment.NoAA)
    }

    Support.Prop3dBinding {
        renderer: sceneEnvironment.renderer
        target: sceneEnvironment
        name: "antialiasing_quality"
        property: "antialiasingQuality"
        value: Value3d.enumeration(sceneEnvironment.renderer.prop("antialiasing_quality"), {
            "medium": SceneEnvironment.Medium,
            "high": SceneEnvironment.High,
            "very_high": SceneEnvironment.VeryHigh
        }, SceneEnvironment.Medium)
    }

    Support.Prop3dBinding {
        renderer: sceneEnvironment.renderer
        target: sceneEnvironment
        name: "temporal_aa_enabled"
        property: "temporalAAEnabled"
        value: sceneEnvironment.renderer.prop("temporal_aa_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: sceneEnvironment.renderer
        target: sceneEnvironment
        name: "temporal_aa_strength"
        property: "temporalAAStrength"
        value: Number(sceneEnvironment.renderer.prop("temporal_aa_strength"))
    }

    Support.Prop3dBinding {
        renderer: sceneEnvironment.renderer
        target: sceneEnvironment
        name: "background_mode"
        property: "backgroundMode"
        value: Value3d.enumeration(sceneEnvironment.renderer.prop("background_mode"), {
            "transparent": SceneEnvironment.Transparent,
            "unspecified": SceneEnvironment.Unspecified,
            "color": SceneEnvironment.Color,
            "skybox": SceneEnvironment.SkyBox,
            "skybox_cube_map": SceneEnvironment.SkyBoxCubeMap
        }, SceneEnvironment.Transparent)
    }

    Support.Prop3dBinding {
        renderer: sceneEnvironment.renderer
        target: sceneEnvironment
        name: "clear_color"
        property: "clearColor"
        value: sceneEnvironment.renderer.prop("clear_color")
    }

    Support.Prop3dBinding {
        renderer: sceneEnvironment.renderer
        target: sceneEnvironment
        name: "depth_test_enabled"
        property: "depthTestEnabled"
        value: sceneEnvironment.renderer.prop("depth_test_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: sceneEnvironment.renderer
        target: sceneEnvironment
        name: "depth_pre_pass_enabled"
        property: "depthPrePassEnabled"
        value: sceneEnvironment.renderer.prop("depth_pre_pass_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: sceneEnvironment.renderer
        target: sceneEnvironment
        name: "ao_strength"
        property: "aoStrength"
        value: Number(sceneEnvironment.renderer.prop("ao_strength"))
    }

    Support.Prop3dBinding {
        renderer: sceneEnvironment.renderer
        target: sceneEnvironment
        name: "ao_distance"
        property: "aoDistance"
        value: Number(sceneEnvironment.renderer.prop("ao_distance"))
    }

    Support.Prop3dBinding {
        renderer: sceneEnvironment.renderer
        target: sceneEnvironment
        name: "ao_softness"
        property: "aoSoftness"
        value: Number(sceneEnvironment.renderer.prop("ao_softness"))
    }

    Support.Prop3dBinding {
        renderer: sceneEnvironment.renderer
        target: sceneEnvironment
        name: "ao_dither"
        property: "aoDither"
        value: sceneEnvironment.renderer.prop("ao_dither") === true
    }

    Support.Prop3dBinding {
        renderer: sceneEnvironment.renderer
        target: sceneEnvironment
        name: "ao_sample_rate"
        property: "aoSampleRate"
        value: Number(sceneEnvironment.renderer.prop("ao_sample_rate"))
    }

    Support.Prop3dBinding {
        renderer: sceneEnvironment.renderer
        target: sceneEnvironment
        name: "ao_bias"
        property: "aoBias"
        value: Number(sceneEnvironment.renderer.prop("ao_bias"))
    }

    Support.Prop3dBinding {
        renderer: sceneEnvironment.renderer
        target: sceneEnvironment
        name: "ao_enabled"
        property: "aoEnabled"
        value: sceneEnvironment.renderer.prop("ao_enabled") === true
    }

    Support.Prop3dBinding {
        renderer: sceneEnvironment.renderer
        target: sceneEnvironment
        name: "probe_exposure"
        property: "probeExposure"
        value: Number(sceneEnvironment.renderer.prop("probe_exposure"))
    }

    Support.Prop3dBinding {
        renderer: sceneEnvironment.renderer
        target: sceneEnvironment
        name: "probe_horizon"
        property: "probeHorizon"
        value: Number(sceneEnvironment.renderer.prop("probe_horizon"))
    }

    Support.Prop3dBinding {
        renderer: sceneEnvironment.renderer
        target: sceneEnvironment
        name: "probe_orientation"
        property: "probeOrientation"
        value: Value3d.vector3d(sceneEnvironment.renderer.prop("probe_orientation"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: sceneEnvironment.renderer
        target: sceneEnvironment
        name: "tonemap_mode"
        property: "tonemapMode"
        value: Value3d.enumeration(sceneEnvironment.renderer.prop("tonemap_mode"), {
            "none": SceneEnvironment.TonemapModeNone,
            "linear": SceneEnvironment.TonemapModeLinear,
            "aces": SceneEnvironment.TonemapModeAces,
            "hejl_dawson": SceneEnvironment.TonemapModeHejlDawson,
            "filmic": SceneEnvironment.TonemapModeFilmic
        }, SceneEnvironment.TonemapModeNone)
    }

    Support.Prop3dBinding {
        renderer: sceneEnvironment.renderer
        target: sceneEnvironment
        name: "skybox_blur_amount"
        property: "skyboxBlurAmount"
        value: Number(sceneEnvironment.renderer.prop("skybox_blur_amount"))
    }

    Support.Prop3dBinding {
        renderer: sceneEnvironment.renderer
        target: sceneEnvironment
        name: "specular_aa_enabled"
        property: "specularAAEnabled"
        value: sceneEnvironment.renderer.prop("specular_aa_enabled") === true
    }
}
