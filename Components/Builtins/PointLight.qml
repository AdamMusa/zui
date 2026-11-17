import QtQuick
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// Light radiating in every direction from a single point, fading with
// distance through its constant, linear and quadratic fade terms.
PointLight {
    id: pointLight

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
        target: pointLight
        property: "rotation"
        value: Value3d.quaternion(renderer.prop("rotation", null))
        when: renderer.hasProp("rotation")
        restoreMode: Binding.RestoreBindingOrValue
    }

    Support.Prop3dBinding {
        renderer: pointLight.renderer
        target: pointLight
        name: "constant_fade"
        property: "constantFade"
        value: Number(pointLight.renderer.prop("constant_fade"))
    }

    Support.Prop3dBinding {
        renderer: pointLight.renderer
        target: pointLight
        name: "linear_fade"
        property: "linearFade"
        value: Number(pointLight.renderer.prop("linear_fade"))
    }

    Support.Prop3dBinding {
        renderer: pointLight.renderer
        target: pointLight
        name: "quadratic_fade"
        property: "quadraticFade"
        value: Number(pointLight.renderer.prop("quadratic_fade"))
    }

    Support.Prop3dBinding {
        renderer: pointLight.renderer
        target: pointLight
        name: "color"
        property: "color"
        value: pointLight.renderer.prop("color")
    }

    Support.Prop3dBinding {
        renderer: pointLight.renderer
        target: pointLight
        name: "ambient_color"
        property: "ambientColor"
        value: pointLight.renderer.prop("ambient_color")
    }

    Support.Prop3dBinding {
        renderer: pointLight.renderer
        target: pointLight
        name: "brightness"
        property: "brightness"
        value: Number(pointLight.renderer.prop("brightness"))
    }

    Support.Prop3dBinding {
        renderer: pointLight.renderer
        target: pointLight
        name: "casts_shadow"
        property: "castsShadow"
        value: pointLight.renderer.prop("casts_shadow") === true
    }

    Support.Prop3dBinding {
        renderer: pointLight.renderer
        target: pointLight
        name: "shadow_bias"
        property: "shadowBias"
        value: Number(pointLight.renderer.prop("shadow_bias"))
    }

    Support.Prop3dBinding {
        renderer: pointLight.renderer
        target: pointLight
        name: "shadow_factor"
        property: "shadowFactor"
        value: Number(pointLight.renderer.prop("shadow_factor"))
    }

    Support.Prop3dBinding {
        renderer: pointLight.renderer
        target: pointLight
        name: "shadow_map_quality"
        property: "shadowMapQuality"
        value: Value3d.enumeration(pointLight.renderer.prop("shadow_map_quality"), {
            "low": Light.ShadowMapQualityLow,
            "medium": Light.ShadowMapQualityMedium,
            "high": Light.ShadowMapQualityHigh,
            "very_high": Light.ShadowMapQualityVeryHigh
        }, Light.ShadowMapQualityLow)
    }

    Support.Prop3dBinding {
        renderer: pointLight.renderer
        target: pointLight
        name: "shadow_map_far"
        property: "shadowMapFar"
        value: Number(pointLight.renderer.prop("shadow_map_far"))
    }

    Support.Prop3dBinding {
        renderer: pointLight.renderer
        target: pointLight
        name: "shadow_filter"
        property: "shadowFilter"
        value: Number(pointLight.renderer.prop("shadow_filter"))
    }

    Support.Prop3dBinding {
        renderer: pointLight.renderer
        target: pointLight
        name: "bake_mode"
        property: "bakeMode"
        value: Value3d.enumeration(pointLight.renderer.prop("bake_mode"), {
            "disabled": Light.BakeModeDisabled,
            "indirect": Light.BakeModeIndirect,
            "all": Light.BakeModeAll
        }, Light.BakeModeDisabled)
    }

    Support.Prop3dBinding {
        renderer: pointLight.renderer
        target: pointLight
        name: "soft_shadow_quality"
        property: "softShadowQuality"
        value: Value3d.enumeration(pointLight.renderer.prop("soft_shadow_quality"), {
            "hard": Light.Hard,
            "pcf4": Light.PCF4,
            "pcf8": Light.PCF8,
            "pcf16": Light.PCF16,
            "pcf32": Light.PCF32,
            "pcf64": Light.PCF64
        }, Light.Hard)
    }

    Support.Prop3dBinding {
        renderer: pointLight.renderer
        target: pointLight
        name: "pcf_factor"
        property: "pcfFactor"
        value: Number(pointLight.renderer.prop("pcf_factor"))
    }
}
