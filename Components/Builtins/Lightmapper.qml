import QtQuick
import QtQuick3D
import "Support" as Support

// Settings for baking lightmaps: sample count, bounce count, bias and
// the indirect light contribution.
Lightmapper {
    id: lightmapper3d

    required property var renderer

    property list<QtObject> propertyBindings: [
        Support.Prop3dBinding {
            renderer: lightmapper3d.renderer
            target: lightmapper3d
            name: "opacity_threshold"
            property: "opacityThreshold"
            value: Number(lightmapper3d.renderer.prop("opacity_threshold"))
        },
        Support.Prop3dBinding {
            renderer: lightmapper3d.renderer
            target: lightmapper3d
            name: "bias"
            property: "bias"
            value: Number(lightmapper3d.renderer.prop("bias"))
        },
        Support.Prop3dBinding {
            renderer: lightmapper3d.renderer
            target: lightmapper3d
            name: "adaptive_bias_enabled"
            property: "adaptiveBiasEnabled"
            value: lightmapper3d.renderer.prop("adaptive_bias_enabled") === true
        },
        Support.Prop3dBinding {
            renderer: lightmapper3d.renderer
            target: lightmapper3d
            name: "indirect_light_enabled"
            property: "indirectLightEnabled"
            value: lightmapper3d.renderer.prop("indirect_light_enabled") === true
        },
        Support.Prop3dBinding {
            renderer: lightmapper3d.renderer
            target: lightmapper3d
            name: "samples"
            property: "samples"
            value: Number(lightmapper3d.renderer.prop("samples"))
        },
        Support.Prop3dBinding {
            renderer: lightmapper3d.renderer
            target: lightmapper3d
            name: "indirect_light_workgroup_size"
            property: "indirectLightWorkgroupSize"
            value: Number(lightmapper3d.renderer.prop("indirect_light_workgroup_size"))
        },
        Support.Prop3dBinding {
            renderer: lightmapper3d.renderer
            target: lightmapper3d
            name: "bounces"
            property: "bounces"
            value: Number(lightmapper3d.renderer.prop("bounces"))
        },
        Support.Prop3dBinding {
            renderer: lightmapper3d.renderer
            target: lightmapper3d
            name: "indirect_light_factor"
            property: "indirectLightFactor"
            value: Number(lightmapper3d.renderer.prop("indirect_light_factor"))
        }
    ]
}
