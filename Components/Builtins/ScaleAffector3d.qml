import QtQuick
import QtQuick3D.Particles3D
import "Support" as Support
import "Support/Value3d.js" as Value3d
import "Support/Scene3dTypes.js" as Scene3dTypes

// Scales particles over their life through a declared curve, so a puff
// can swell as it fades. Qt spells the saw-tooth scaling type SewSaw,
// which Ruby writes as :sew_saw.
ScaleAffector3D {
    id: scaleAffector3d

    required property var renderer

    position: Value3d.vector3d(renderer.prop("position", null), renderer.prop("x", 0), renderer.prop("y", 0), renderer.prop("z", 0))
    eulerRotation: Value3d.vector3d(renderer.prop("euler_rotation", null), renderer.prop("rotation_x", 0), renderer.prop("rotation_y", 0), renderer.prop("rotation_z", 0))
    scale: Value3d.vector3d(renderer.prop("scale", null), 1, 1, 1)
    pivot: Value3d.vector3d(renderer.prop("pivot", null), 0, 0, 0)
    opacity: Number(renderer.prop("opacity", 1))
    visible: renderer.prop("visible", true) !== false
    staticFlags: Number(renderer.prop("static_flags", 0))
    system: renderer.ownerOrReference(Scene3dTypes.particleSystems, "system")
    particles: renderer.sceneObjects(renderer.prop("particles", []))

    // eulerRotation and rotation describe the same orientation, so the
    // quaternion is applied only when Ruby declared one.
    Binding {
        target: scaleAffector3d
        property: "rotation"
        value: Value3d.quaternion(renderer.prop("rotation", null))
        when: renderer.hasProp("rotation")
        restoreMode: Binding.RestoreBindingOrValue
    }

    Support.Prop3dBinding {
        renderer: scaleAffector3d.renderer
        target: scaleAffector3d
        name: "min_size"
        property: "minSize"
        value: Number(scaleAffector3d.renderer.prop("min_size"))
    }

    Support.Prop3dBinding {
        renderer: scaleAffector3d.renderer
        target: scaleAffector3d
        name: "max_size"
        property: "maxSize"
        value: Number(scaleAffector3d.renderer.prop("max_size"))
    }

    Support.Prop3dBinding {
        renderer: scaleAffector3d.renderer
        target: scaleAffector3d
        name: "duration"
        property: "duration"
        value: Number(scaleAffector3d.renderer.prop("duration"))
    }

    Support.Prop3dBinding {
        renderer: scaleAffector3d.renderer
        target: scaleAffector3d
        name: "type"
        property: "type"
        value: Value3d.enumeration(scaleAffector3d.renderer.prop("type"), {
            "linear": ScaleAffector3D.Linear,
            "sew_saw": ScaleAffector3D.SewSaw,
            "sine_wave": ScaleAffector3D.SineWave,
            "abs_sine_wave": ScaleAffector3D.AbsSineWave,
            "step": ScaleAffector3D.Step,
            "smooth_step": ScaleAffector3D.SmoothStep
        }, ScaleAffector3D.Linear)
    }

    Support.Prop3dBinding {
        renderer: scaleAffector3d.renderer
        target: scaleAffector3d
        name: "easing_curve"
        property: "easingCurve"
        value: Value3d.easing(scaleAffector3d.renderer.prop("easing_curve"))
    }

    Support.Prop3dBinding {
        renderer: scaleAffector3d.renderer
        target: scaleAffector3d
        name: "enabled"
        property: "enabled"
        value: scaleAffector3d.renderer.prop("enabled") === true
    }
}
