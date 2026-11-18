import QtQuick
import QtQuick as Quick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Item {
  required property var renderer
      implicitWidth: 0
      implicitHeight: 0
      Quick.FontLoader {
        source: renderer.assetUrl(renderer.prop("source", ""))
        onStatusChanged: {
          if (renderer.subscribed("status")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "status", { value: status, name: name })
          if (status === Quick.FontLoader.Ready && renderer.subscribed("loaded")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "loaded", { name: name })
          if (status === Quick.FontLoader.Error) renderer.componentError("font_load_failed", "Unable to load the declared font", { source: String(source) })
        }
      }
    }
