import QtQuick
import "Support/OptionalModuleState.js" as OptionalModuleState

// The Qt Quick 3D viewport, and the root of every Zui 3D scene.
//
// Qt Quick 3D is an optional Qt module, so the viewport itself lives in a
// support scene that is loaded on demand. That keeps a missing module a
// reported condition instead of a broken adapter, exactly as model_view_3d
// already does.
Item {
    id: view3dHost

    required property var renderer
    property bool failureReported: false

    function reportUnavailable() {
        if (failureReported)
            return

        failureReported = true
        renderer.componentError("qtquick3d_unavailable",
                                "Qt Quick 3D is not installed. Install qt6-quick3d and assimp.", {})
    }

    implicitWidth: Number(renderer.prop("width", 420))
    implicitHeight: Number(renderer.prop("height", 420))
    clip: true
    Component.onCompleted: {
        if (OptionalModuleState.quick3dUnavailable) {
            reportUnavailable()
            return
        }
        sceneLoader.setSource(Qt.resolvedUrl("Support/View3dScene.qml"), { "renderer": renderer })
    }

    Loader {
        id: sceneLoader

        anchors.fill: parent
        asynchronous: false
        onStatusChanged: {
            if (status === Loader.Error) {
                OptionalModuleState.quick3dUnavailable = true
                view3dHost.reportUnavailable()
            }
        }
    }
}
