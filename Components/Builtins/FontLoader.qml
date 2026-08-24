import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Item {
  required property var renderer
      implicitWidth: 0
      implicitHeight: 0
      FontLoader {
        source: String(renderer.prop("source", ""))
        onStatusChanged: {
          if (renderer.subscribed("status")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "status", { value: status, name: name })
          if (status === FontLoader.Ready && renderer.subscribed("loaded")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "loaded", { name: name })
          if (status === FontLoader.Error) renderer.componentError("font_load_failed", "Unable to load the declared font", { source: String(source) })
        }
      }
    }
