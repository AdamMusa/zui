import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

ZuiControls.CursorSurface {
  required property var renderer
      implicitWidth: Number(renderer.prop("width", contentItem.implicitWidth)); implicitHeight: Number(renderer.prop("height", contentItem.implicitHeight))
      current: renderer.prop("current", false) === true; outline: renderer.prop("outline", false) === true; bordered: renderer.prop("bordered", false) === true
      hasCursor: renderer.prop("cursor", false) === true; foreground: renderer.prop("foreground", renderer.foreground)
      accent: renderer.prop("accent", Color.accent); fill: renderer.prop("fill", Style.hoverFillFor(foreground, accent))
      currentFill: renderer.prop("current_fill", Style.selectedFillFor(foreground, accent))
      Column { id: contentItem; anchors.centerIn: parent; Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent } }
      MouseArea { anchors.fill: parent; onClicked: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", {}) }
    }
