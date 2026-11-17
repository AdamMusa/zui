import QtQuick
import QtQuick3D.Helpers
import "Support/Scene3dTypes.js" as Scene3dTypes

// Exposes an instancing table as a list model, one row per instance, so
// a two-dimensional view can list what a GPU instance field contains.
InstanceModel {
    id: instanceModel

    required property var renderer

    instancingTable: renderer.childObjectOrReference(Scene3dTypes.instancing, "instancing_table")
}
