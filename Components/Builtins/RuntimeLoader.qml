import QtQuick
import QtQuick3D.AssetUtils
import "Support" as Support
import "Support/Value3d.js" as Value3d
import "Support/Scene3dTypes.js" as Scene3dTypes

// Loads a glTF, OBJ or FBX asset into the scene while the application
// runs, rather than at build time. The loaded hierarchy becomes real
// scene nodes, so anything declared inside the loader sits alongside
// them. Reports its bounds once the asset is in, which is what a viewer
// needs to frame it.
RuntimeLoader {
    id: runtimeLoader

    required property var renderer

    position: Value3d.vector3d(renderer.prop("position", null), renderer.prop("x", 0), renderer.prop("y", 0), renderer.prop("z", 0))
    eulerRotation: Value3d.vector3d(renderer.prop("euler_rotation", null), renderer.prop("rotation_x", 0), renderer.prop("rotation_y", 0), renderer.prop("rotation_z", 0))
    scale: Value3d.vector3d(renderer.prop("scale", null), 1, 1, 1)
    pivot: Value3d.vector3d(renderer.prop("pivot", null), 0, 0, 0)
    opacity: Number(renderer.prop("opacity", 1))
    visible: renderer.prop("visible", true) !== false
    staticFlags: Number(renderer.prop("static_flags", 0))
    instancing: renderer.childObjectOrReference(Scene3dTypes.instancing, "instancing")

    onStatusChanged: {
        renderer.emitEvent("status", {
            "value": status,
            "error": errorString
        });
        if (status === RuntimeLoader.Success) {
            renderer.emitEvent("loaded", {
                "source": String(source),
                "minimum": [bounds.minimum.x, bounds.minimum.y, bounds.minimum.z],
                "maximum": [bounds.maximum.x, bounds.maximum.y, bounds.maximum.z]
            });
        } else if (status === RuntimeLoader.Error) {
            renderer.componentError("model_load_failed", errorString, {
                "source": String(source)
            });
        }
    }
    onBoundsChanged: {
        renderer.emitEvent("bounds", {
            "minimum": [bounds.minimum.x, bounds.minimum.y, bounds.minimum.z],
            "maximum": [bounds.maximum.x, bounds.maximum.y, bounds.maximum.z]
        });
    }

    // eulerRotation and rotation describe the same orientation, so the
    // quaternion is applied only when Ruby declared one.
    Binding {
        target: runtimeLoader
        property: "rotation"
        value: Value3d.quaternion(renderer.prop("rotation", null))
        when: renderer.hasProp("rotation")
        restoreMode: Binding.RestoreBindingOrValue
    }

    Support.Prop3dBinding {
        renderer: runtimeLoader.renderer
        target: runtimeLoader
        name: "source"
        property: "source"
        value: runtimeLoader.renderer.assetUrl(runtimeLoader.renderer.prop("source"))
    }
}
