import QtQuick
import QtQuick3D.Helpers
import "Support" as Support

// An overlay reporting what the view is spending its frame on. It is a
// Qt Quick item, so it sits over the viewport, and it reports on the
// view_3d it is declared inside unless source names another one.
DebugView {
    id: debugView3d

    required property var renderer

    source: renderer.sceneObject(renderer.prop("source", "")) || renderer.viewport()

    Support.Prop3dBinding {
        renderer: debugView3d.renderer
        target: debugView3d
        name: "resource_details"
        property: "resourceDetailsVisible"
        value: debugView3d.renderer.prop("resource_details") === true
    }
}
