import QtQuick
import QtQuick3D.Helpers
import QtQuick3D
import "Support/Value3d.js" as Value3d
import "Support/Scene3dTypes.js" as Scene3dTypes

// Builds a real node per row of an instancing table instead of drawing
// the instances on the GPU, for when each copy needs to be pickable or
// carry its own children.
InstanceRepeater {
    id: instanceRepeater

    required property var renderer

    position: Value3d.vector3d(renderer.prop("position", null), renderer.prop("x", 0), renderer.prop("y", 0), renderer.prop("z", 0))
    eulerRotation: Value3d.vector3d(renderer.prop("euler_rotation", null), renderer.prop("rotation_x", 0), renderer.prop("rotation_y", 0), renderer.prop("rotation_z", 0))
    scale: Value3d.vector3d(renderer.prop("scale", null), 1, 1, 1)
    pivot: Value3d.vector3d(renderer.prop("pivot", null), 0, 0, 0)
    opacity: Number(renderer.prop("opacity", 1))
    visible: renderer.prop("visible", true) !== false
    staticFlags: Number(renderer.prop("static_flags", 0))
    instancingTable: renderer.childObjectOrReference(Scene3dTypes.instancing, "instancing_table")

    // Qt's InstanceRepeater builds one node per row of the instancing table.
    // Zui replicates the declared subtree into each of them, because the
    // protocol carries no per-index delegate expressions.
    property var sceneChildHosts: []

    function collectHosts() {
        var hosts = [];
        for (var index = 0; index < count; index++) {
            var slot = objectAt(index);
            if (slot)
                hosts.push(slot);
        }
        sceneChildHosts = hosts;
    }

    delegate: Node {}
    onObjectAdded: function (index, object) {
        collectHosts();
        renderer.emitEvent("object_added", {
            "index": index
        });
    }
    onObjectRemoved: function (index, object) {
        collectHosts();
        renderer.emitEvent("object_removed", {
            "index": index
        });
    }

    // eulerRotation and rotation describe the same orientation, so the
    // quaternion is applied only when Ruby declared one.
    Binding {
        target: instanceRepeater
        property: "rotation"
        value: Value3d.quaternion(renderer.prop("rotation", null))
        when: renderer.hasProp("rotation")
        restoreMode: Binding.RestoreBindingOrValue
    }
}
