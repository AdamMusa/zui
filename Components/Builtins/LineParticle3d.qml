import QtQuick
import QtQuick3D.Particles3D
import "Support" as Support
import "Support/Value3d.js" as Value3d
import "Support/Scene3dTypes.js" as Scene3dTypes

// Sprite particles drawn as a ribbon through the positions each particle
// has passed, for a trail, a streak of rain or a bolt.
LineParticle3D {
    id: lineParticle3d

    required property var renderer

    sprite: renderer.childObjectOrReference(Scene3dTypes.textures, "sprite")
    colorTable: renderer.sceneObject(renderer.prop("color_table", ""))
    spriteSequence: renderer.childObjectOrReference(["sprite_sequence_3d"], "sprite_sequence")
    lights: renderer.childObjectsAndReferences(Scene3dTypes.lights, "lights")

    // A particle takes the system it is declared inside unless `system` names
    // another one. Qt offers no settable `system` property on a particle,
    // only setSystem(), so the resolved value is applied through the call.
    readonly property var resolvedSystem: renderer.ownerOrReference(Scene3dTypes.particleSystems, "system")

    onResolvedSystemChanged: if (resolvedSystem)
        setSystem(resolvedSystem)
    Component.onCompleted: if (resolvedSystem)
        setSystem(resolvedSystem)

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "segment_count"
        property: "segmentCount"
        value: Number(lineParticle3d.renderer.prop("segment_count"))
    }

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "alpha_fade"
        property: "alphaFade"
        value: Number(lineParticle3d.renderer.prop("alpha_fade"))
    }

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "scale_multiplier"
        property: "scaleMultiplier"
        value: Number(lineParticle3d.renderer.prop("scale_multiplier"))
    }

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "texcoord_multiplier"
        property: "texcoordMultiplier"
        value: Number(lineParticle3d.renderer.prop("texcoord_multiplier"))
    }

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "length"
        property: "length"
        value: Number(lineParticle3d.renderer.prop("length"))
    }

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "length_variation"
        property: "lengthVariation"
        value: Number(lineParticle3d.renderer.prop("length_variation"))
    }

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "length_delta_min"
        property: "lengthDeltaMin"
        value: Number(lineParticle3d.renderer.prop("length_delta_min"))
    }

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "eol_fade_out_duration"
        property: "eolFadeOutDuration"
        value: Number(lineParticle3d.renderer.prop("eol_fade_out_duration"))
    }

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "texcoord_mode"
        property: "texcoordMode"
        value: Value3d.enumeration(lineParticle3d.renderer.prop("texcoord_mode"), {
            "absolute": LineParticle3D.Absolute,
            "relative": LineParticle3D.Relative,
            "fill": LineParticle3D.Fill
        }, LineParticle3D.Absolute)
    }

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "blend_mode"
        property: "blendMode"
        value: Value3d.enumeration(lineParticle3d.renderer.prop("blend_mode"), {
            "source_over": LineParticle3D.SourceOver,
            "screen": LineParticle3D.Screen,
            "multiply": LineParticle3D.Multiply
        }, LineParticle3D.SourceOver)
    }

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "billboard"
        property: "billboard"
        value: lineParticle3d.renderer.prop("billboard") === true
    }

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "particle_scale"
        property: "particleScale"
        value: Number(lineParticle3d.renderer.prop("particle_scale"))
    }

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "offset_x"
        property: "offsetX"
        value: Number(lineParticle3d.renderer.prop("offset_x"))
    }

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "offset_y"
        property: "offsetY"
        value: Number(lineParticle3d.renderer.prop("offset_y"))
    }

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "casts_reflections"
        property: "castsReflections"
        value: lineParticle3d.renderer.prop("casts_reflections") === true
    }

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "max_amount"
        property: "maxAmount"
        value: Number(lineParticle3d.renderer.prop("max_amount"))
    }

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "color"
        property: "color"
        value: lineParticle3d.renderer.prop("color")
    }

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "color_variation"
        property: "colorVariation"
        value: Value3d.vector4d(lineParticle3d.renderer.prop("color_variation"), 0, 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "unified_color_variation"
        property: "unifiedColorVariation"
        value: lineParticle3d.renderer.prop("unified_color_variation") === true
    }

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "fade_in_effect"
        property: "fadeInEffect"
        value: Value3d.enumeration(lineParticle3d.renderer.prop("fade_in_effect"), {
            "none": LineParticle3D.FadeNone,
            "opacity": LineParticle3D.FadeOpacity,
            "scale": LineParticle3D.FadeScale
        }, LineParticle3D.FadeNone)
    }

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "fade_out_effect"
        property: "fadeOutEffect"
        value: Value3d.enumeration(lineParticle3d.renderer.prop("fade_out_effect"), {
            "none": LineParticle3D.FadeNone,
            "opacity": LineParticle3D.FadeOpacity,
            "scale": LineParticle3D.FadeScale
        }, LineParticle3D.FadeNone)
    }

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "fade_in_duration"
        property: "fadeInDuration"
        value: Number(lineParticle3d.renderer.prop("fade_in_duration"))
    }

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "fade_out_duration"
        property: "fadeOutDuration"
        value: Number(lineParticle3d.renderer.prop("fade_out_duration"))
    }

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "align_mode"
        property: "alignMode"
        value: Value3d.enumeration(lineParticle3d.renderer.prop("align_mode"), {
            "none": LineParticle3D.AlignNone,
            "towards_target": LineParticle3D.AlignTowardsTarget,
            "towards_start_velocity": LineParticle3D.AlignTowardsStartVelocity
        }, LineParticle3D.AlignNone)
    }

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "align_target_position"
        property: "alignTargetPosition"
        value: Value3d.vector3d(lineParticle3d.renderer.prop("align_target_position"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "has_transparency"
        property: "hasTransparency"
        value: lineParticle3d.renderer.prop("has_transparency") === true
    }

    Support.Prop3dBinding {
        renderer: lineParticle3d.renderer
        target: lineParticle3d
        name: "sort_mode"
        property: "sortMode"
        value: Value3d.enumeration(lineParticle3d.renderer.prop("sort_mode"), {
            "none": LineParticle3D.SortNone,
            "newest": LineParticle3D.SortNewest,
            "oldest": LineParticle3D.SortOldest,
            "distance": LineParticle3D.SortDistance
        }, LineParticle3D.SortNone)
    }
}
