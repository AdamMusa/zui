import QtQuick
import QtQuick3D
import "Support/Value3d.js" as Value3d

// Repeats everything declared inside it once per model entry. Qt's Repeater3D
// instantiates one empty node per entry and Zui replicates the declared
// subtree into each of them, so `model: 8` builds eight copies of the branch.
Node {
    id: repeater3d

    required property var renderer

    // Scene3dBranch reads this to know where the declared children belong.
    property var sceneChildHosts: []

    function collectHosts() {
        var hosts = []
        for (var index = 0; index < nativeRepeater.count; index++) {
            var slot = nativeRepeater.objectAt(index)
            if (slot)
                hosts.push(slot)
        }
        sceneChildHosts = hosts
    }

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

    Repeater3D {
        id: nativeRepeater

        model: renderer.prop("model", 0)
        delegate: Node {
            required property int index

            position: Value3d.vector3d(repeater3d.renderer.prop("spacing", null), 0, 0, 0)
                .times(index)
        }
        onObjectAdded: function(index, object) {
            repeater3d.collectHosts()
            repeater3d.renderer.emitEvent("object_added", { "index": index })
        }
        onObjectRemoved: function(index, object) {
            repeater3d.collectHosts()
            repeater3d.renderer.emitEvent("object_removed", { "index": index })
        }
    }

    Binding {
        target: repeater3d
        property: "rotation"
        value: Value3d.quaternion(renderer.prop("rotation", null))
        when: renderer.hasProp("rotation")
        restoreMode: Binding.RestoreBindingOrValue
    }
}
