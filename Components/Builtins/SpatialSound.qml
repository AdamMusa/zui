import QtQuick
import QtQuick3D.SpatialAudio
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// A sound at a place in the scene. It is attenuated by distance,
// occluded by rooms, and can be given a directivity so it is louder in
// front of itself than behind.
SpatialSound {
    id: spatialSound

    required property var renderer

    position: Value3d.vector3d(renderer.prop("position", null), renderer.prop("x", 0), renderer.prop("y", 0), renderer.prop("z", 0))
    eulerRotation: Value3d.vector3d(renderer.prop("euler_rotation", null), renderer.prop("rotation_x", 0), renderer.prop("rotation_y", 0), renderer.prop("rotation_z", 0))
    scale: Value3d.vector3d(renderer.prop("scale", null), 1, 1, 1)
    pivot: Value3d.vector3d(renderer.prop("pivot", null), 0, 0, 0)
    opacity: Number(renderer.prop("opacity", 1))
    visible: renderer.prop("visible", true) !== false
    staticFlags: Number(renderer.prop("static_flags", 0))

    // eulerRotation and rotation describe the same orientation, so the
    // quaternion is applied only when Ruby declared one.
    Binding {
        target: spatialSound
        property: "rotation"
        value: Value3d.quaternion(renderer.prop("rotation", null))
        when: renderer.hasProp("rotation")
        restoreMode: Binding.RestoreBindingOrValue
    }

    Support.Prop3dBinding {
        renderer: spatialSound.renderer
        target: spatialSound
        name: "source"
        property: "source"
        value: spatialSound.renderer.assetUrl(spatialSound.renderer.prop("source"))
    }

    Support.Prop3dBinding {
        renderer: spatialSound.renderer
        target: spatialSound
        name: "volume"
        property: "volume"
        value: Number(spatialSound.renderer.prop("volume"))
    }

    Support.Prop3dBinding {
        renderer: spatialSound.renderer
        target: spatialSound
        name: "distance_model"
        property: "distanceModel"
        value: Value3d.enumeration(spatialSound.renderer.prop("distance_model"), {
            "logarithmic": SpatialSound.Logarithmic,
            "linear": SpatialSound.Linear,
            "manual_attenuation": SpatialSound.ManualAttenuation
        }, SpatialSound.Logarithmic)
    }

    Support.Prop3dBinding {
        renderer: spatialSound.renderer
        target: spatialSound
        name: "size"
        property: "size"
        value: Number(spatialSound.renderer.prop("size"))
    }

    Support.Prop3dBinding {
        renderer: spatialSound.renderer
        target: spatialSound
        name: "distance_cutoff"
        property: "distanceCutoff"
        value: Number(spatialSound.renderer.prop("distance_cutoff"))
    }

    Support.Prop3dBinding {
        renderer: spatialSound.renderer
        target: spatialSound
        name: "manual_attenuation"
        property: "manualAttenuation"
        value: Number(spatialSound.renderer.prop("manual_attenuation"))
    }

    Support.Prop3dBinding {
        renderer: spatialSound.renderer
        target: spatialSound
        name: "occlusion_intensity"
        property: "occlusionIntensity"
        value: Number(spatialSound.renderer.prop("occlusion_intensity"))
    }

    Support.Prop3dBinding {
        renderer: spatialSound.renderer
        target: spatialSound
        name: "directivity"
        property: "directivity"
        value: Number(spatialSound.renderer.prop("directivity"))
    }

    Support.Prop3dBinding {
        renderer: spatialSound.renderer
        target: spatialSound
        name: "directivity_order"
        property: "directivityOrder"
        value: Number(spatialSound.renderer.prop("directivity_order"))
    }

    Support.Prop3dBinding {
        renderer: spatialSound.renderer
        target: spatialSound
        name: "near_field_gain"
        property: "nearFieldGain"
        value: Number(spatialSound.renderer.prop("near_field_gain"))
    }

    Support.Prop3dBinding {
        renderer: spatialSound.renderer
        target: spatialSound
        name: "loops"
        property: "loops"
        value: Value3d.loops(spatialSound.renderer.prop("loops"), SpatialSound.Infinite)
    }

    Support.Prop3dBinding {
        renderer: spatialSound.renderer
        target: spatialSound
        name: "auto_play"
        property: "autoPlay"
        value: spatialSound.renderer.prop("auto_play") === true
    }
}
