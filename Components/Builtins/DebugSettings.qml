import QtQuick
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// Rendering diagnostics for a scene environment: wireframe, a material
// channel override, and the shadow and cascade bounds Qt can draw.
DebugSettings {
    id: debugSettings

    required property var renderer

    property list<QtObject> propertyBindings: [
        Support.Prop3dBinding {
            renderer: debugSettings.renderer
            target: debugSettings
            name: "material_override"
            property: "materialOverride"
            value: Value3d.enumeration(debugSettings.renderer.prop("material_override"), {
                "none": DebugSettings.None,
                "base_color": DebugSettings.BaseColor,
                "roughness": DebugSettings.Roughness,
                "metalness": DebugSettings.Metalness,
                "diffuse": DebugSettings.Diffuse,
                "specular": DebugSettings.Specular,
                "shadow_occlusion": DebugSettings.ShadowOcclusion,
                "emission": DebugSettings.Emission,
                "ambient_occlusion": DebugSettings.AmbientOcclusion,
                "normals": DebugSettings.Normals,
                "tangents": DebugSettings.Tangents,
                "binormals": DebugSettings.Binormals,
                "f0": DebugSettings.F0
            }, DebugSettings.None)
        },
        Support.Prop3dBinding {
            renderer: debugSettings.renderer
            target: debugSettings
            name: "wireframe_enabled"
            property: "wireframeEnabled"
            value: debugSettings.renderer.prop("wireframe_enabled") === true
        },
        Support.Prop3dBinding {
            renderer: debugSettings.renderer
            target: debugSettings
            name: "draw_directional_light_shadow_boxes"
            property: "drawDirectionalLightShadowBoxes"
            value: debugSettings.renderer.prop("draw_directional_light_shadow_boxes") === true
        },
        Support.Prop3dBinding {
            renderer: debugSettings.renderer
            target: debugSettings
            name: "draw_shadow_casting_bounds"
            property: "drawShadowCastingBounds"
            value: debugSettings.renderer.prop("draw_shadow_casting_bounds") === true
        },
        Support.Prop3dBinding {
            renderer: debugSettings.renderer
            target: debugSettings
            name: "draw_shadow_receiving_bounds"
            property: "drawShadowReceivingBounds"
            value: debugSettings.renderer.prop("draw_shadow_receiving_bounds") === true
        },
        Support.Prop3dBinding {
            renderer: debugSettings.renderer
            target: debugSettings
            name: "draw_cascades"
            property: "drawCascades"
            value: debugSettings.renderer.prop("draw_cascades") === true
        },
        Support.Prop3dBinding {
            renderer: debugSettings.renderer
            target: debugSettings
            name: "draw_scene_cascade_intersection"
            property: "drawSceneCascadeIntersection"
            value: debugSettings.renderer.prop("draw_scene_cascade_intersection") === true
        },
        Support.Prop3dBinding {
            renderer: debugSettings.renderer
            target: debugSettings
            name: "disable_shadow_camera_update"
            property: "disableShadowCameraUpdate"
            value: debugSettings.renderer.prop("disable_shadow_camera_update") === true
        }
    ]
}
