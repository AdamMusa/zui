import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.Drawer {
  id: drawerRoot

  required property var renderer
  readonly property bool requestedOpen: renderer.prop("opened", false) === true
    && renderer.prop("visible", true) !== false
  readonly property string contentLayout: String(renderer.prop("layout", "column"))
  property bool synchronizing: false

  function edgeValue(value) {
    var name = String(value || "left")
    if (name === "right") return Qt.RightEdge
    if (name === "top") return Qt.TopEdge
    if (name === "bottom") return Qt.BottomEdge
    return Qt.LeftEdge
  }

  function closePolicyValue(value) {
    var names = Array.isArray(value) ? value : [value || "escape_and_outside"]
    var result = 0
    for (var index = 0; index < names.length; index++) {
      var name = String(names[index])
      if (name === "none") continue
      if (name === "escape" || name === "escape_and_outside") result |= QQC.Popup.CloseOnEscape
      if (name === "outside" || name === "escape_and_outside") result |= QQC.Popup.CloseOnPressOutside
      if (name === "outside_parent") result |= QQC.Popup.CloseOnPressOutsideParent
      if (name === "release_outside") result |= QQC.Popup.CloseOnReleaseOutside
      if (name === "release_outside_parent") result |= QQC.Popup.CloseOnReleaseOutsideParent
    }
    return result
  }

  function syncOpenState() {
    if (requestedOpen === opened) return
    synchronizing = true
    if (requestedOpen) open()
    else close()
    synchronizing = false
  }

  edge: edgeValue(renderer.prop("edge", "left"))
  modal: renderer.prop("modal", true) !== false
  dim: renderer.prop("dim", modal) !== false
  interactive: renderer.prop("interactive", true) !== false
  dragMargin: Number(renderer.prop("drag_margin", Qt.styleHints.startDragDistance))
  closePolicy: closePolicyValue(renderer.prop("close_policy", "escape_and_outside"))
  width: Number(renderer.prop("width", edge === Qt.LeftEdge || edge === Qt.RightEdge ? 360 : 640))
  height: Number(renderer.prop("height", edge === Qt.TopEdge || edge === Qt.BottomEdge ? 280 : 640))
  enabled: renderer.prop("enabled", true) !== false
  padding: Number(renderer.prop("padding", Style.spacing.lg))

  background: Rectangle {
    color: renderer.prop("background", Color.background)
    radius: Number(renderer.prop("radius", Style.cornerRadius))
    border.width: String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0
    border.color: renderer.prop("border_color", "transparent")
  }

  contentItem: Loader {
    sourceComponent: drawerRoot.contentLayout === "row" ? rowContent
      : (drawerRoot.contentLayout === "stack" ? stackContent : columnContent)
  }

  Component {
    id: columnContent
    Column {
      spacing: Number(renderer.prop("spacing", Style.spacing.md))
      Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
    }
  }

  Component {
    id: rowContent
    Row {
      spacing: Number(renderer.prop("spacing", Style.spacing.md))
      Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
    }
  }

  Component {
    id: stackContent
    Item {
      Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
    }
  }

  Component.onCompleted: syncOpenState()
  onRequestedOpenChanged: syncOpenState()
  onOpened: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "open",
    { value: true, position: position })
  onClosed: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "close",
    { value: false, position: position })
  onAboutToShow: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "about_to_show", {})
  onAboutToHide: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "about_to_hide", {})
  onPositionChanged: {
    if (renderer.subscribed("position_change"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "position_change", { value: position })
  }
  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
  onActiveFocusChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    activeFocus ? "focus" : "blur", {})
}
