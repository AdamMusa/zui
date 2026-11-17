import QtQuick
import QtQuick3D.Particles3D
import "Support" as Support
import "Support/Value3d.js" as Value3d
import "Support/Scene3dTypes.js" as Scene3dTypes

// Particles drawn as camera-facing sprites: the cheapest kind, and the
// one to reach for for smoke, fire and sparks. A sprite sequence animates
// the image, and a colour table maps each particle's age to a colour.
SpriteParticle3D {
    id: spriteParticle3d

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
        renderer: spriteParticle3d.renderer
        target: spriteParticle3d
        name: "blend_mode"
        property: "blendMode"
        value: Value3d.enumeration(spriteParticle3d.renderer.prop("blend_mode"), {
            "source_over": SpriteParticle3D.SourceOver,
            "screen": SpriteParticle3D.Screen,
            "multiply": SpriteParticle3D.Multiply
        }, SpriteParticle3D.SourceOver)
    }

    Support.Prop3dBinding {
        renderer: spriteParticle3d.renderer
        target: spriteParticle3d
        name: "billboard"
        property: "billboard"
        value: spriteParticle3d.renderer.prop("billboard") === true
    }

    Support.Prop3dBinding {
        renderer: spriteParticle3d.renderer
        target: spriteParticle3d
        name: "particle_scale"
        property: "particleScale"
        value: Number(spriteParticle3d.renderer.prop("particle_scale"))
    }

    Support.Prop3dBinding {
        renderer: spriteParticle3d.renderer
        target: spriteParticle3d
        name: "offset_x"
        property: "offsetX"
        value: Number(spriteParticle3d.renderer.prop("offset_x"))
    }

    Support.Prop3dBinding {
        renderer: spriteParticle3d.renderer
        target: spriteParticle3d
        name: "offset_y"
        property: "offsetY"
        value: Number(spriteParticle3d.renderer.prop("offset_y"))
    }

    Support.Prop3dBinding {
        renderer: spriteParticle3d.renderer
        target: spriteParticle3d
        name: "casts_reflections"
        property: "castsReflections"
        value: spriteParticle3d.renderer.prop("casts_reflections") === true
    }

    Support.Prop3dBinding {
        renderer: spriteParticle3d.renderer
        target: spriteParticle3d
        name: "max_amount"
        property: "maxAmount"
        value: Number(spriteParticle3d.renderer.prop("max_amount"))
    }

    Support.Prop3dBinding {
        renderer: spriteParticle3d.renderer
        target: spriteParticle3d
        name: "color"
        property: "color"
        value: spriteParticle3d.renderer.prop("color")
    }

    Support.Prop3dBinding {
        renderer: spriteParticle3d.renderer
        target: spriteParticle3d
        name: "color_variation"
        property: "colorVariation"
        value: Value3d.vector4d(spriteParticle3d.renderer.prop("color_variation"), 0, 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: spriteParticle3d.renderer
        target: spriteParticle3d
        name: "unified_color_variation"
        property: "unifiedColorVariation"
        value: spriteParticle3d.renderer.prop("unified_color_variation") === true
    }

    Support.Prop3dBinding {
        renderer: spriteParticle3d.renderer
        target: spriteParticle3d
        name: "fade_in_effect"
        property: "fadeInEffect"
        value: Value3d.enumeration(spriteParticle3d.renderer.prop("fade_in_effect"), {
            "none": SpriteParticle3D.FadeNone,
            "opacity": SpriteParticle3D.FadeOpacity,
            "scale": SpriteParticle3D.FadeScale
        }, SpriteParticle3D.FadeNone)
    }

    Support.Prop3dBinding {
        renderer: spriteParticle3d.renderer
        target: spriteParticle3d
        name: "fade_out_effect"
        property: "fadeOutEffect"
        value: Value3d.enumeration(spriteParticle3d.renderer.prop("fade_out_effect"), {
            "none": SpriteParticle3D.FadeNone,
            "opacity": SpriteParticle3D.FadeOpacity,
            "scale": SpriteParticle3D.FadeScale
        }, SpriteParticle3D.FadeNone)
    }

    Support.Prop3dBinding {
        renderer: spriteParticle3d.renderer
        target: spriteParticle3d
        name: "fade_in_duration"
        property: "fadeInDuration"
        value: Number(spriteParticle3d.renderer.prop("fade_in_duration"))
    }

    Support.Prop3dBinding {
        renderer: spriteParticle3d.renderer
        target: spriteParticle3d
        name: "fade_out_duration"
        property: "fadeOutDuration"
        value: Number(spriteParticle3d.renderer.prop("fade_out_duration"))
    }

    Support.Prop3dBinding {
        renderer: spriteParticle3d.renderer
        target: spriteParticle3d
        name: "align_mode"
        property: "alignMode"
        value: Value3d.enumeration(spriteParticle3d.renderer.prop("align_mode"), {
            "none": SpriteParticle3D.AlignNone,
            "towards_target": SpriteParticle3D.AlignTowardsTarget,
            "towards_start_velocity": SpriteParticle3D.AlignTowardsStartVelocity
        }, SpriteParticle3D.AlignNone)
    }

    Support.Prop3dBinding {
        renderer: spriteParticle3d.renderer
        target: spriteParticle3d
        name: "align_target_position"
        property: "alignTargetPosition"
        value: Value3d.vector3d(spriteParticle3d.renderer.prop("align_target_position"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: spriteParticle3d.renderer
        target: spriteParticle3d
        name: "has_transparency"
        property: "hasTransparency"
        value: spriteParticle3d.renderer.prop("has_transparency") === true
    }

    Support.Prop3dBinding {
        renderer: spriteParticle3d.renderer
        target: spriteParticle3d
        name: "sort_mode"
        property: "sortMode"
        value: Value3d.enumeration(spriteParticle3d.renderer.prop("sort_mode"), {
            "none": SpriteParticle3D.SortNone,
            "newest": SpriteParticle3D.SortNewest,
            "oldest": SpriteParticle3D.SortOldest,
            "distance": SpriteParticle3D.SortDistance
        }, SpriteParticle3D.SortNone)
    }
}
