import QtQuick
import QtQuick3D.Particles3D
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d
import "Support/Scene3dTypes.js" as Scene3dTypes

// Takes a model apart into one particle per vertex or triangle and blends
// it between its own shape and the particle motion, which is how a model
// appears to assemble or crumble.
ModelBlendParticle3D {
    id: modelBlendParticle3d

    required property var renderer

    endNode: renderer.sceneObject(renderer.prop("end_node", ""))
    activationNode: renderer.sceneObject(renderer.prop("activation_node", ""))

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
            source: Value3d.meshSource(modelBlendParticle3d.renderer, modelBlendParticle3d.renderer.prop("source", "#Sphere"))
            materials: modelBlendParticle3d.renderer.childObjectsAndReferences(Scene3dTypes.materials, "materials")
            geometry: modelBlendParticle3d.renderer.childObjectOrReference(Scene3dTypes.geometries, "geometry")
        }
    }

    property list<QtObject> propertyBindings: [
        Support.Prop3dBinding {
            renderer: modelBlendParticle3d.renderer
            target: modelBlendParticle3d
            name: "model_blend_mode"
            property: "modelBlendMode"
            value: Value3d.enumeration(modelBlendParticle3d.renderer.prop("model_blend_mode"), {
                "explode": ModelBlendParticle3D.Explode,
                "construct": ModelBlendParticle3D.Construct,
                "transfer": ModelBlendParticle3D.Transfer
            }, ModelBlendParticle3D.Explode)
        },
        Support.Prop3dBinding {
            renderer: modelBlendParticle3d.renderer
            target: modelBlendParticle3d
            name: "end_time"
            property: "endTime"
            value: Number(modelBlendParticle3d.renderer.prop("end_time"))
        },
        Support.Prop3dBinding {
            renderer: modelBlendParticle3d.renderer
            target: modelBlendParticle3d
            name: "emit_mode"
            property: "emitMode"
            value: Value3d.enumeration(modelBlendParticle3d.renderer.prop("emit_mode"), {
                "sequential": ModelBlendParticle3D.Sequential,
                "random": ModelBlendParticle3D.Random,
                "activation": ModelBlendParticle3D.Activation
            }, ModelBlendParticle3D.Sequential)
        },
        Support.Prop3dBinding {
            renderer: modelBlendParticle3d.renderer
            target: modelBlendParticle3d
            name: "max_amount"
            property: "maxAmount"
            value: Number(modelBlendParticle3d.renderer.prop("max_amount"))
        },
        Support.Prop3dBinding {
            renderer: modelBlendParticle3d.renderer
            target: modelBlendParticle3d
            name: "color"
            property: "color"
            value: modelBlendParticle3d.renderer.prop("color")
        },
        Support.Prop3dBinding {
            renderer: modelBlendParticle3d.renderer
            target: modelBlendParticle3d
            name: "color_variation"
            property: "colorVariation"
            value: Value3d.vector4d(modelBlendParticle3d.renderer.prop("color_variation"), 0, 0, 0, 0)
        },
        Support.Prop3dBinding {
            renderer: modelBlendParticle3d.renderer
            target: modelBlendParticle3d
            name: "unified_color_variation"
            property: "unifiedColorVariation"
            value: modelBlendParticle3d.renderer.prop("unified_color_variation") === true
        },
        Support.Prop3dBinding {
            renderer: modelBlendParticle3d.renderer
            target: modelBlendParticle3d
            name: "fade_in_effect"
            property: "fadeInEffect"
            value: Value3d.enumeration(modelBlendParticle3d.renderer.prop("fade_in_effect"), {
                "none": ModelBlendParticle3D.FadeNone,
                "opacity": ModelBlendParticle3D.FadeOpacity,
                "scale": ModelBlendParticle3D.FadeScale
            }, ModelBlendParticle3D.FadeNone)
        },
        Support.Prop3dBinding {
            renderer: modelBlendParticle3d.renderer
            target: modelBlendParticle3d
            name: "fade_out_effect"
            property: "fadeOutEffect"
            value: Value3d.enumeration(modelBlendParticle3d.renderer.prop("fade_out_effect"), {
                "none": ModelBlendParticle3D.FadeNone,
                "opacity": ModelBlendParticle3D.FadeOpacity,
                "scale": ModelBlendParticle3D.FadeScale
            }, ModelBlendParticle3D.FadeNone)
        },
        Support.Prop3dBinding {
            renderer: modelBlendParticle3d.renderer
            target: modelBlendParticle3d
            name: "fade_in_duration"
            property: "fadeInDuration"
            value: Number(modelBlendParticle3d.renderer.prop("fade_in_duration"))
        },
        Support.Prop3dBinding {
            renderer: modelBlendParticle3d.renderer
            target: modelBlendParticle3d
            name: "fade_out_duration"
            property: "fadeOutDuration"
            value: Number(modelBlendParticle3d.renderer.prop("fade_out_duration"))
        },
        Support.Prop3dBinding {
            renderer: modelBlendParticle3d.renderer
            target: modelBlendParticle3d
            name: "align_mode"
            property: "alignMode"
            value: Value3d.enumeration(modelBlendParticle3d.renderer.prop("align_mode"), {
                "none": ModelBlendParticle3D.AlignNone,
                "towards_target": ModelBlendParticle3D.AlignTowardsTarget,
                "towards_start_velocity": ModelBlendParticle3D.AlignTowardsStartVelocity
            }, ModelBlendParticle3D.AlignNone)
        },
        Support.Prop3dBinding {
            renderer: modelBlendParticle3d.renderer
            target: modelBlendParticle3d
            name: "align_target_position"
            property: "alignTargetPosition"
            value: Value3d.vector3d(modelBlendParticle3d.renderer.prop("align_target_position"), 0, 0, 0)
        },
        Support.Prop3dBinding {
            renderer: modelBlendParticle3d.renderer
            target: modelBlendParticle3d
            name: "has_transparency"
            property: "hasTransparency"
            value: modelBlendParticle3d.renderer.prop("has_transparency") === true
        },
        Support.Prop3dBinding {
            renderer: modelBlendParticle3d.renderer
            target: modelBlendParticle3d
            name: "sort_mode"
            property: "sortMode"
            value: Value3d.enumeration(modelBlendParticle3d.renderer.prop("sort_mode"), {
                "none": ModelBlendParticle3D.SortNone,
                "newest": ModelBlendParticle3D.SortNewest,
                "oldest": ModelBlendParticle3D.SortOldest,
                "distance": ModelBlendParticle3D.SortDistance
            }, ModelBlendParticle3D.SortNone)
        }
    ]
}
