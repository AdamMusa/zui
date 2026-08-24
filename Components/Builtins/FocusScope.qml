import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

FocusScope {
  required property var renderer
      id: nativeFocusScope
      implicitWidth: Number(renderer.prop("width", focusContent.implicitWidth))
      implicitHeight: Number(renderer.prop("height", focusContent.implicitHeight))
      focus: renderer.prop("focus", false) === true
      function syncRequestedFocus() {
        if (renderer.prop("active_focus", false) === true) forceActiveFocus()
      }
      onActiveFocusChanged: {
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, activeFocus ? "focus" : "blur", { value: activeFocus })
      }
      Component.onCompleted: syncRequestedFocus()
      Connections { target: root; function onNodeChanged() { nativeFocusScope.syncRequestedFocus() } }
      Item {
        id: focusContent
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
        Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
      }
    }
