import QtMultimedia
import QtQuick

Item {
    id: screenRoot

    property var renderer: null
    property alias screenCapture: nativeCapture
    property int handledCommandRevision: -1

    function selectedScreen() {
        var screens = Application.screens || [];
        var requested = renderer ? renderer.prop("screen", 0) : 0;
        if (typeof requested === "number") {
            if (requested >= 0 && requested < screens.length)
                return screens[requested];
            if (renderer)
                renderer.componentError("screen_not_found", "The declared screen does not exist", {
                    "screen": String(requested)
                });
            return null;
        }

        for (var index = 0; index < screens.length; index++) if (screens[index].name === String(requested)) {
            return screens[index];
        }
        if (renderer)
            renderer.componentError("screen_not_found", "The declared screen does not exist", {
                "screen": String(requested)
            });
        return null;
    }

    function command() {
        if (!renderer)
            return ;

        var revision = Number(renderer.prop("command_revision", 0));
        if (revision === handledCommandRevision)
            return ;

        handledCommandRevision = revision;
        var value = String(renderer.prop("command", ""));
        if (value === "start")
            nativeCapture.start();
        else if (value === "stop")
            nativeCapture.stop();
    }

    Component.onCompleted: command()

    ScreenCapture {
        id: nativeCapture

        screen: screenRoot.selectedScreen()
        active: renderer && renderer.prop("active", false) === true && screenRoot.selectedScreen() !== null
        onActiveChanged: {
            if (renderer) {
                renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, active ? "start" : "stop", {
            });
            }
        }
        onErrorOccurred: function(error, errorString) {
            renderer.componentError("screen_capture_failed", errorString, {
                "native_code": error
            });
        }
    }

    Connections {
        function onNodeChanged() {
            screenRoot.command();
        }

        target: renderer
    }

}
