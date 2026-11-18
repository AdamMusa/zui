import QtQuick
import QtQuick3D
import "Support/Value3d.js" as Value3d

// Loads a Qt Quick 3D sub-scene from a QML asset on demand, so a heavy branch
// of a scene is only built when the application asks for it.
Loader3D {
    id: loader3d

    required property var renderer

    position: Value3d.vector3d(renderer.prop("position", null), renderer.prop("x", 0),
                               renderer.prop("y", 0), renderer.prop("z", 0))
    eulerRotation: Value3d.vector3d(renderer.prop("euler_rotation", null),
                                    renderer.prop("rotation_x", 0),
                                    renderer.prop("rotation_y", 0),
                                    renderer.prop("rotation_z", 0))
    scale: Value3d.vector3d(renderer.prop("scale", null), 1, 1, 1)
    pivot: Value3d.vector3d(renderer.prop("pivot", null), 0, 0, 0)
    opacity: Number(renderer.prop("opacity", 1))
    visible: renderer.prop("visible", true) !== false
    staticFlags: Number(renderer.prop("static_flags", 0))

    active: renderer.prop("active", true) !== false
    asynchronous: renderer.prop("asynchronous", false) === true
    source: renderer.assetUrl(renderer.prop("source", ""))

    onStatusChanged: {
        renderer.emitEvent("status", { "value": status, "progress": progress })
        if (status === Loader3D.Ready)
            renderer.emitEvent("loaded", { "source": String(source) })
        else if (status === Loader3D.Error)
            renderer.componentError("scene3d_load_failed", "Unable to load the 3D scene source",
                                    { "source": String(source) })
    }

    Binding {
        target: loader3d
        property: "rotation"
        value: Value3d.quaternion(renderer.prop("rotation", null))
        when: renderer.hasProp("rotation")
        restoreMode: Binding.RestoreBindingOrValue
    }
}
