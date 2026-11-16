import QtQuick
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// Light radiating in a cone, fading between inner_cone_angle and
// cone_angle at the edge of the beam.
SpotLight {
    id: spotLight

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
        target: spotLight
        property: "rotation"
        value: Value3d.quaternion(renderer.prop("rotation", null))
        when: renderer.hasProp("rotation")
        restoreMode: Binding.RestoreBindingOrValue
    }

    Support.Prop3dBinding {
        renderer: spotLight.renderer
        target: spotLight
        name: "constant_fade"
        property: "constantFade"
        value: Number(spotLight.renderer.prop("constant_fade"))
    }

    Support.Prop3dBinding {
        renderer: spotLight.renderer
        target: spotLight
        name: "linear_fade"
        property: "linearFade"
        value: Number(spotLight.renderer.prop("linear_fade"))
    }

    Support.Prop3dBinding {
        renderer: spotLight.renderer
        target: spotLight
        name: "quadratic_fade"
        property: "quadraticFade"
        value: Number(spotLight.renderer.prop("quadratic_fade"))
    }

    Support.Prop3dBinding {
        renderer: spotLight.renderer
        target: spotLight
        name: "cone_angle"
        property: "coneAngle"
        value: Number(spotLight.renderer.prop("cone_angle"))
    }

    Support.Prop3dBinding {
        renderer: spotLight.renderer
        target: spotLight
        name: "inner_cone_angle"
        property: "innerConeAngle"
        value: Number(spotLight.renderer.prop("inner_cone_angle"))
    }

    Support.Prop3dBinding {
        renderer: spotLight.renderer
        target: spotLight
        name: "color"
        property: "color"
        value: spotLight.renderer.prop("color")
    }

    Support.Prop3dBinding {
        renderer: spotLight.renderer
        target: spotLight
        name: "ambient_color"
        property: "ambientColor"
        value: spotLight.renderer.prop("ambient_color")
    }

    Support.Prop3dBinding {
        renderer: spotLight.renderer
        target: spotLight
        name: "brightness"
        property: "brightness"
        value: Number(spotLight.renderer.prop("brightness"))
    }

    Support.Prop3dBinding {
        renderer: spotLight.renderer
        target: spotLight
        name: "casts_shadow"
        property: "castsShadow"
        value: spotLight.renderer.prop("casts_shadow") === true
    }

    Support.Prop3dBinding {
        renderer: spotLight.renderer
        target: spotLight
        name: "shadow_bias"
        property: "shadowBias"
        value: Number(spotLight.renderer.prop("shadow_bias"))
    }

    Support.Prop3dBinding {
        renderer: spotLight.renderer
        target: spotLight
        name: "shadow_factor"
        property: "shadowFactor"
        value: Number(spotLight.renderer.prop("shadow_factor"))
    }

    Support.Prop3dBinding {
        renderer: spotLight.renderer
        target: spotLight
        name: "shadow_map_quality"
        property: "shadowMapQuality"
        value: Value3d.enumeration(spotLight.renderer.prop("shadow_map_quality"), {
            "low": Light.ShadowMapQualityLow,
            "medium": Light.ShadowMapQualityMedium,
            "high": Light.ShadowMapQualityHigh,
            "very_high": Light.ShadowMapQualityVeryHigh
        }, Light.ShadowMapQualityLow)
    }

    Support.Prop3dBinding {
        renderer: spotLight.renderer
        target: spotLight
        name: "shadow_map_far"
        property: "shadowMapFar"
        value: Number(spotLight.renderer.prop("shadow_map_far"))
    }

    Support.Prop3dBinding {
        renderer: spotLight.renderer
        target: spotLight
        name: "shadow_filter"
        property: "shadowFilter"
        value: Number(spotLight.renderer.prop("shadow_filter"))
    }

    Support.Prop3dBinding {
        renderer: spotLight.renderer
        target: spotLight
        name: "bake_mode"
        property: "bakeMode"
        value: Value3d.enumeration(spotLight.renderer.prop("bake_mode"), {
            "disabled": Light.BakeModeDisabled,
            "indirect": Light.BakeModeIndirect,
            "all": Light.BakeModeAll
        }, Light.BakeModeDisabled)
    }

    Support.Prop3dBinding {
        renderer: spotLight.renderer
        target: spotLight
        name: "soft_shadow_quality"
        property: "softShadowQuality"
        value: Value3d.enumeration(spotLight.renderer.prop("soft_shadow_quality"), {
            "hard": Light.Hard,
            "pcf4": Light.PCF4,
            "pcf8": Light.PCF8,
            "pcf16": Light.PCF16,
            "pcf32": Light.PCF32,
            "pcf64": Light.PCF64
        }, Light.Hard)
    }

    Support.Prop3dBinding {
        renderer: spotLight.renderer
        target: spotLight
        name: "pcf_factor"
        property: "pcfFactor"
        value: Number(spotLight.renderer.prop("pcf_factor"))
    }
}
