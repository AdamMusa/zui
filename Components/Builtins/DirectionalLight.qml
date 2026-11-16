import QtQuick
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// Light arriving from one direction everywhere in the scene, like
// sunlight. Its position is irrelevant; only its rotation matters.
// Cascaded shadow maps are configured through csm_num_splits.
DirectionalLight {
    id: directionalLight

    required property var renderer

    position: Value3d.vector3d(renderer.prop("position", null), renderer.prop("x", 0), renderer.prop("y", 0), renderer.prop("z", 0))
    eulerRotation: Value3d.vector3d(renderer.prop("euler_rotation", null), renderer.prop("rotation_x", 0), renderer.prop("rotation_y", 0), renderer.prop("rotation_z", 0))
    scale: Value3d.vector3d(renderer.prop("scale", null), 1, 1, 1)
    pivot: Value3d.vector3d(renderer.prop("pivot", null), 0, 0, 0)
    opacity: Number(renderer.prop("opacity", 1))
    visible: renderer.prop("visible", true) !== false
    staticFlags: Number(renderer.prop("static_flags", 0))
    scope: renderer.sceneObject(renderer.prop("scope", ""))

    // eulerRotation and rotation describe the same orientation, so the
    // quaternion is applied only when Ruby declared one.
    Binding {
        target: directionalLight
        property: "rotation"
        value: Value3d.quaternion(renderer.prop("rotation", null))
        when: renderer.hasProp("rotation")
        restoreMode: Binding.RestoreBindingOrValue
    }

    Support.Prop3dBinding {
        renderer: directionalLight.renderer
        target: directionalLight
        name: "csm_split1"
        property: "csmSplit1"
        value: Number(directionalLight.renderer.prop("csm_split1"))
    }

    Support.Prop3dBinding {
        renderer: directionalLight.renderer
        target: directionalLight
        name: "csm_split2"
        property: "csmSplit2"
        value: Number(directionalLight.renderer.prop("csm_split2"))
    }

    Support.Prop3dBinding {
        renderer: directionalLight.renderer
        target: directionalLight
        name: "csm_split3"
        property: "csmSplit3"
        value: Number(directionalLight.renderer.prop("csm_split3"))
    }

    Support.Prop3dBinding {
        renderer: directionalLight.renderer
        target: directionalLight
        name: "csm_num_splits"
        property: "csmNumSplits"
        value: Number(directionalLight.renderer.prop("csm_num_splits"))
    }

    Support.Prop3dBinding {
        renderer: directionalLight.renderer
        target: directionalLight
        name: "csm_blend_ratio"
        property: "csmBlendRatio"
        value: Number(directionalLight.renderer.prop("csm_blend_ratio"))
    }

    Support.Prop3dBinding {
        renderer: directionalLight.renderer
        target: directionalLight
        name: "color"
        property: "color"
        value: directionalLight.renderer.prop("color")
    }

    Support.Prop3dBinding {
        renderer: directionalLight.renderer
        target: directionalLight
        name: "ambient_color"
        property: "ambientColor"
        value: directionalLight.renderer.prop("ambient_color")
    }

    Support.Prop3dBinding {
        renderer: directionalLight.renderer
        target: directionalLight
        name: "brightness"
        property: "brightness"
        value: Number(directionalLight.renderer.prop("brightness"))
    }

    Support.Prop3dBinding {
        renderer: directionalLight.renderer
        target: directionalLight
        name: "casts_shadow"
        property: "castsShadow"
        value: directionalLight.renderer.prop("casts_shadow") === true
    }

    Support.Prop3dBinding {
        renderer: directionalLight.renderer
        target: directionalLight
        name: "shadow_bias"
        property: "shadowBias"
        value: Number(directionalLight.renderer.prop("shadow_bias"))
    }

    Support.Prop3dBinding {
        renderer: directionalLight.renderer
        target: directionalLight
        name: "shadow_factor"
        property: "shadowFactor"
        value: Number(directionalLight.renderer.prop("shadow_factor"))
    }

    Support.Prop3dBinding {
        renderer: directionalLight.renderer
        target: directionalLight
        name: "shadow_map_quality"
        property: "shadowMapQuality"
        value: Value3d.enumeration(directionalLight.renderer.prop("shadow_map_quality"), {
            "low": Light.ShadowMapQualityLow,
            "medium": Light.ShadowMapQualityMedium,
            "high": Light.ShadowMapQualityHigh,
            "very_high": Light.ShadowMapQualityVeryHigh
        }, Light.ShadowMapQualityLow)
    }

    Support.Prop3dBinding {
        renderer: directionalLight.renderer
        target: directionalLight
        name: "shadow_map_far"
        property: "shadowMapFar"
        value: Number(directionalLight.renderer.prop("shadow_map_far"))
    }

    Support.Prop3dBinding {
        renderer: directionalLight.renderer
        target: directionalLight
        name: "shadow_filter"
        property: "shadowFilter"
        value: Number(directionalLight.renderer.prop("shadow_filter"))
    }

    Support.Prop3dBinding {
        renderer: directionalLight.renderer
        target: directionalLight
        name: "bake_mode"
        property: "bakeMode"
        value: Value3d.enumeration(directionalLight.renderer.prop("bake_mode"), {
            "disabled": Light.BakeModeDisabled,
            "indirect": Light.BakeModeIndirect,
            "all": Light.BakeModeAll
        }, Light.BakeModeDisabled)
    }

    Support.Prop3dBinding {
        renderer: directionalLight.renderer
        target: directionalLight
        name: "soft_shadow_quality"
        property: "softShadowQuality"
        value: Value3d.enumeration(directionalLight.renderer.prop("soft_shadow_quality"), {
            "hard": Light.Hard,
            "pcf4": Light.PCF4,
            "pcf8": Light.PCF8,
            "pcf16": Light.PCF16,
            "pcf32": Light.PCF32,
            "pcf64": Light.PCF64
        }, Light.Hard)
    }

    Support.Prop3dBinding {
        renderer: directionalLight.renderer
        target: directionalLight
        name: "pcf_factor"
        property: "pcfFactor"
        value: Number(directionalLight.renderer.prop("pcf_factor"))
    }
}
