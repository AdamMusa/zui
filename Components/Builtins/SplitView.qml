import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

QQC.SplitView {
  required property var renderer
      implicitWidth: Number(renderer.prop("width", 560))
      implicitHeight: Number(renderer.prop("height", 320))
      orientation: String(renderer.prop("orientation", "horizontal")) === "vertical" ? Qt.Vertical : Qt.Horizontal
      function currentSizes() {
        var sizes = []
        for (var index = 0; index < splitChildren.count; index++) {
          var child = splitChildren.itemAt(index)
          sizes.push(orientation === Qt.Horizontal ? child.width : child.height)
        }
        return sizes
      }
      onResizingChanged: {
        if (!resizing && renderer.subscribed("resize"))
          renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "resize", { sizes: currentSizes() })
      }
      Repeater {
        id: splitChildren
        model: renderer.node.children || []
        delegate: renderer.splitChildDelegateComponent
      }
    }
