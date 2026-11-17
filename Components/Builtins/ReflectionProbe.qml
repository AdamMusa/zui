import QtQuick
import QtQuick3D
import "Support" as Support
import "Support/Value3d.js" as Value3d

// Captures the scene around a point into a cube map so nearby materials
// can reflect it, with a box volume and parallax correction for a room.
ReflectionProbe {
    id: reflectionProbe

    required property var renderer

    position: Value3d.vector3d(renderer.prop("position", null), renderer.prop("x", 0), renderer.prop("y", 0), renderer.prop("z", 0))
    eulerRotation: Value3d.vector3d(renderer.prop("euler_rotation", null), renderer.prop("rotation_x", 0), renderer.prop("rotation_y", 0), renderer.prop("rotation_z", 0))
    scale: Value3d.vector3d(renderer.prop("scale", null), 1, 1, 1)
    pivot: Value3d.vector3d(renderer.prop("pivot", null), 0, 0, 0)
    opacity: Number(renderer.prop("opacity", 1))
    visible: renderer.prop("visible", true) !== false
    staticFlags: Number(renderer.prop("static_flags", 0))
    texture: renderer.childObjectOrReference(["cube_map_texture"], "texture")

    // eulerRotation and rotation describe the same orientation, so the
    // quaternion is applied only when Ruby declared one.
    Binding {
        target: reflectionProbe
        property: "rotation"
        value: Value3d.quaternion(renderer.prop("rotation", null))
        when: renderer.hasProp("rotation")
        restoreMode: Binding.RestoreBindingOrValue
    }

    Support.Prop3dBinding {
        renderer: reflectionProbe.renderer
        target: reflectionProbe
        name: "quality"
        property: "quality"
        value: Value3d.enumeration(reflectionProbe.renderer.prop("quality"), {
            "very_low": ReflectionProbe.VeryLow,
            "low": ReflectionProbe.Low,
            "medium": ReflectionProbe.Medium,
            "high": ReflectionProbe.High,
            "very_high": ReflectionProbe.VeryHigh
        }, ReflectionProbe.VeryLow)
    }

    Support.Prop3dBinding {
        renderer: reflectionProbe.renderer
        target: reflectionProbe
        name: "clear_color"
        property: "clearColor"
        value: reflectionProbe.renderer.prop("clear_color")
    }

    Support.Prop3dBinding {
        renderer: reflectionProbe.renderer
        target: reflectionProbe
        name: "refresh_mode"
        property: "refreshMode"
        value: Value3d.enumeration(reflectionProbe.renderer.prop("refresh_mode"), {
            "first_frame": ReflectionProbe.FirstFrame,
            "every_frame": ReflectionProbe.EveryFrame
        }, ReflectionProbe.FirstFrame)
    }

    Support.Prop3dBinding {
        renderer: reflectionProbe.renderer
        target: reflectionProbe
        name: "time_slicing"
        property: "timeSlicing"
        value: Value3d.enumeration(reflectionProbe.renderer.prop("time_slicing"), {
            "none": ReflectionProbe.None,
            "all_faces_at_once": ReflectionProbe.AllFacesAtOnce,
            "individual_faces": ReflectionProbe.IndividualFaces
        }, ReflectionProbe.None)
    }

    Support.Prop3dBinding {
        renderer: reflectionProbe.renderer
        target: reflectionProbe
        name: "parallax_correction"
        property: "parallaxCorrection"
        value: reflectionProbe.renderer.prop("parallax_correction") === true
    }

    Support.Prop3dBinding {
        renderer: reflectionProbe.renderer
        target: reflectionProbe
        name: "box_size"
        property: "boxSize"
        value: Value3d.vector3d(reflectionProbe.renderer.prop("box_size"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: reflectionProbe.renderer
        target: reflectionProbe
        name: "box_offset"
        property: "boxOffset"
        value: Value3d.vector3d(reflectionProbe.renderer.prop("box_offset"), 0, 0, 0)
    }

    Support.Prop3dBinding {
        renderer: reflectionProbe.renderer
        target: reflectionProbe
        name: "debug_view"
        property: "debugView"
        value: reflectionProbe.renderer.prop("debug_view") === true
    }
}
