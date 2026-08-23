import QtQuick
import "Support/OptionalModuleState.js" as OptionalModuleState

Item {
    id: modelHost

    required property var renderer
    property bool failureReported: false

    function reportUnavailable() {
        if (failureReported)
            return ;

        failureReported = true;
        renderer.componentError("qtquick3d_unavailable", "Qt Quick 3D is not installed. Install qt6-quick3d and assimp.", {
        });
    }

    implicitWidth: Number(renderer.prop("width", 420))
    implicitHeight: Number(renderer.prop("height", 420))
    clip: true
    Component.onCompleted: {
        if (OptionalModuleState.quick3dUnavailable) {
            reportUnavailable();
            return ;
        }
        sceneLoader.setSource(Qt.resolvedUrl("Support/ModelView3dScene.qml"), {
            "renderer": renderer
        });
    }

    Rectangle {
        anchors.fill: parent
        color: renderer.prop("background", "transparent")
    }

    Loader {
        id: sceneLoader

        anchors.fill: parent
        asynchronous: true
        onStatusChanged: {
            if (status === Loader.Error) {
                OptionalModuleState.quick3dUnavailable = true;
                modelHost.reportUnavailable();
            }
        }
    }

}
