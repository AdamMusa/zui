import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.ToolBar {
  id: toolBarRoot

  required property var renderer
  readonly property string contentLayout: String(renderer.prop("layout", "row"))

  position: String(renderer.prop("position", "header")) === "footer"
    ? QQC.ToolBar.Footer : QQC.ToolBar.Header
  implicitWidth: Number(renderer.prop("width", 640))
  implicitHeight: Number(renderer.prop("height", 52))
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false
  padding: Number(renderer.prop("padding", Style.spacing.sm))
  LayoutMirroring.enabled: String(renderer.prop("layout_direction", "left_to_right")) === "right_to_left"
  LayoutMirroring.childrenInherit: true

  background: Rectangle {
    color: renderer.prop("background", Color.background)
    radius: Number(renderer.prop("radius", 0))
    border.width: String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0
    border.color: renderer.prop("border_color", "transparent")
  }

  contentItem: Loader {
    sourceComponent: toolBarRoot.contentLayout === "column" ? columnContent : rowContent
  }

  Component {
    id: rowContent
    Row {
      spacing: Number(renderer.prop("spacing", Style.spacing.sm))
      Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
    }
  }

  Component {
    id: columnContent
    Column {
      spacing: Number(renderer.prop("spacing", Style.spacing.sm))
      Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
    }
  }

  TapHandler {
    enabled: renderer.subscribed("click")
    onTapped: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", {})
  }
  onPositionChanged: {
    if (renderer.subscribed("position_change"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "position_change",
        { value: position === QQC.ToolBar.Footer ? "footer" : "header" })
  }
  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
  onActiveFocusChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    activeFocus ? "focus" : "blur", {})
}
