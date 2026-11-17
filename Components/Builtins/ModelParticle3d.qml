import QtQuick
import QtQuick3D.Particles3D
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d
import "Support/Scene3dTypes.js" as Scene3dTypes

// Particles drawn as real geometry rather than sprites, instanced on the
// GPU, for debris, coins or anything that has to have volume.
ModelParticle3D {
    id: modelParticle3d

    required property var renderer

    // A particle takes the system it is declared inside unless `system` names
    // another one. Qt offers no settable `system` property on a particle,
    // only setSystem(), so the resolved value is applied through the call.
    readonly property var resolvedSystem: renderer.ownerOrReference(Scene3dTypes.particleSystems, "system")

    onResolvedSystemChanged: if (resolvedSystem)
        setSystem(resolvedSystem)
    Component.onCompleted: if (resolvedSystem)
        setSystem(resolvedSystem)
    // Qt takes the per-particle model as a Component, so the mesh and
    // materials are declared here the way model_3d declares them.
    delegate: Component {
        Model {
            source: Value3d.meshSource(modelParticle3d.renderer, modelParticle3d.renderer.prop("source", "#Sphere"))
            materials: modelParticle3d.renderer.childObjectsAndReferences(Scene3dTypes.materials, "materials")
            geometry: modelParticle3d.renderer.childObjectOrReference(Scene3dTypes.geometries, "geometry")
        }
    }

    property list<QtObject> propertyBindings: [
        Support.Prop3dBinding {
            renderer: modelParticle3d.renderer
            target: modelParticle3d
            name: "max_amount"
            property: "maxAmount"
            value: Number(modelParticle3d.renderer.prop("max_amount"))
        },
        Support.Prop3dBinding {
            renderer: modelParticle3d.renderer
            target: modelParticle3d
            name: "color"
            property: "color"
            value: modelParticle3d.renderer.prop("color")
        },
        Support.Prop3dBinding {
            renderer: modelParticle3d.renderer
            target: modelParticle3d
            name: "color_variation"
            property: "colorVariation"
            value: Value3d.vector4d(modelParticle3d.renderer.prop("color_variation"), 0, 0, 0, 0)
        },
        Support.Prop3dBinding {
            renderer: modelParticle3d.renderer
            target: modelParticle3d
            name: "unified_color_variation"
            property: "unifiedColorVariation"
            value: modelParticle3d.renderer.prop("unified_color_variation") === true
        },
        Support.Prop3dBinding {
            renderer: modelParticle3d.renderer
            target: modelParticle3d
            name: "fade_in_effect"
            property: "fadeInEffect"
            value: Value3d.enumeration(modelParticle3d.renderer.prop("fade_in_effect"), {
                "none": ModelParticle3D.FadeNone,
                "opacity": ModelParticle3D.FadeOpacity,
                "scale": ModelParticle3D.FadeScale
            }, ModelParticle3D.FadeNone)
        },
        Support.Prop3dBinding {
            renderer: modelParticle3d.renderer
            target: modelParticle3d
            name: "fade_out_effect"
            property: "fadeOutEffect"
            value: Value3d.enumeration(modelParticle3d.renderer.prop("fade_out_effect"), {
                "none": ModelParticle3D.FadeNone,
                "opacity": ModelParticle3D.FadeOpacity,
                "scale": ModelParticle3D.FadeScale
            }, ModelParticle3D.FadeNone)
        },
        Support.Prop3dBinding {
            renderer: modelParticle3d.renderer
            target: modelParticle3d
            name: "fade_in_duration"
            property: "fadeInDuration"
            value: Number(modelParticle3d.renderer.prop("fade_in_duration"))
        },
        Support.Prop3dBinding {
            renderer: modelParticle3d.renderer
            target: modelParticle3d
            name: "fade_out_duration"
            property: "fadeOutDuration"
            value: Number(modelParticle3d.renderer.prop("fade_out_duration"))
        },
        Support.Prop3dBinding {
            renderer: modelParticle3d.renderer
            target: modelParticle3d
            name: "align_mode"
            property: "alignMode"
            value: Value3d.enumeration(modelParticle3d.renderer.prop("align_mode"), {
                "none": ModelParticle3D.AlignNone,
                "towards_target": ModelParticle3D.AlignTowardsTarget,
                "towards_start_velocity": ModelParticle3D.AlignTowardsStartVelocity
            }, ModelParticle3D.AlignNone)
        },
        Support.Prop3dBinding {
            renderer: modelParticle3d.renderer
            target: modelParticle3d
            name: "align_target_position"
            property: "alignTargetPosition"
            value: Value3d.vector3d(modelParticle3d.renderer.prop("align_target_position"), 0, 0, 0)
        },
        Support.Prop3dBinding {
            renderer: modelParticle3d.renderer
            target: modelParticle3d
            name: "has_transparency"
            property: "hasTransparency"
            value: modelParticle3d.renderer.prop("has_transparency") === true
        },
        Support.Prop3dBinding {
            renderer: modelParticle3d.renderer
            target: modelParticle3d
            name: "sort_mode"
            property: "sortMode"
            value: Value3d.enumeration(modelParticle3d.renderer.prop("sort_mode"), {
                "none": ModelParticle3D.SortNone,
                "newest": ModelParticle3D.SortNewest,
                "oldest": ModelParticle3D.SortOldest,
                "distance": ModelParticle3D.SortDistance
            }, ModelParticle3D.SortNone)
        }
    ]
}
