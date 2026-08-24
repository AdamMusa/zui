import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

ZuiControls.PanelKeyCatcher {
  required property var renderer
      blocked: renderer.prop("blocked", false) === true
      implicitWidth: keyContent.implicitWidth
      implicitHeight: keyContent.implicitHeight
      onMoveRequested: function(dx, dy) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "move", { dx: dx, dy: dy }) }
      onActivateRequested: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "activate", {})
      onReturnRequested: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "return", {})
      onCloseRequested: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "close", {})
      onDeleteRequested: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "delete", {})
      onTabRequested: function(direction) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "tab", { direction: direction }) }
      onTextKey: function(text) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "text", { text: text }) }
      Column {
        id: keyContent
        Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
      }
    }
