import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

StackLayout {
  required property var renderer
      implicitWidth: Number(renderer.prop("width", 420))
      implicitHeight: Number(renderer.prop("height", 280))
      currentIndex: Math.max(0, Math.min(count - 1, Number(renderer.prop("current_index", 0))))
      onCurrentIndexChanged: {
        if (renderer.subscribed("change"))
          renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: currentIndex })
      }
      Repeater { model: renderer.node.children || []; delegate: renderer.layoutChildDelegateComponent }
    }
