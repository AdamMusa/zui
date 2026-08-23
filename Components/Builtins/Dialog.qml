import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.Dialog {
  id: dialogRoot

  required property var renderer
  readonly property bool requestedOpen: renderer.prop("opened", false) === true
    && renderer.prop("visible", true) !== false
  readonly property string contentLayout: String(renderer.prop("layout", "column"))
  readonly property bool centered: renderer.prop("centered", true) !== false
  readonly property bool hasExplicitX: renderer.node && renderer.node.props
    && renderer.node.props.x !== undefined
  readonly property bool hasExplicitY: renderer.node && renderer.node.props
    && renderer.node.props.y !== undefined

  function standardButtonsValue(value) {
    var names = Array.isArray(value) ? value : (value === null || value === undefined ? [] : [value])
    var result = QQC.Dialog.NoButton
    for (var index = 0; index < names.length; index++) {
      var name = String(names[index])
      if (name === "ok") result |= QQC.Dialog.Ok
      else if (name === "save") result |= QQC.Dialog.Save
      else if (name === "save_all") result |= QQC.Dialog.SaveAll
      else if (name === "open") result |= QQC.Dialog.Open
      else if (name === "yes") result |= QQC.Dialog.Yes
      else if (name === "yes_to_all") result |= QQC.Dialog.YesToAll
      else if (name === "no") result |= QQC.Dialog.No
      else if (name === "no_to_all") result |= QQC.Dialog.NoToAll
      else if (name === "abort") result |= QQC.Dialog.Abort
      else if (name === "retry") result |= QQC.Dialog.Retry
      else if (name === "ignore") result |= QQC.Dialog.Ignore
      else if (name === "close") result |= QQC.Dialog.Close
      else if (name === "cancel") result |= QQC.Dialog.Cancel
      else if (name === "discard") result |= QQC.Dialog.Discard
      else if (name === "help") result |= QQC.Dialog.Help
      else if (name === "apply") result |= QQC.Dialog.Apply
      else if (name === "reset") result |= QQC.Dialog.Reset
      else if (name === "restore_defaults") result |= QQC.Dialog.RestoreDefaults
    }
    return result
  }

  function closePolicyValue(value) {
    var names = Array.isArray(value) ? value : [value || "escape_and_outside"]
    var result = 0
    for (var index = 0; index < names.length; index++) {
      var name = String(names[index])
      if (name === "escape" || name === "escape_and_outside") result |= QQC.Popup.CloseOnEscape
      if (name === "outside" || name === "escape_and_outside") result |= QQC.Popup.CloseOnPressOutside
      if (name === "outside_parent") result |= QQC.Popup.CloseOnPressOutsideParent
    }
    return result
  }

  function syncOpenState() {
    if (requestedOpen === opened) return
    if (requestedOpen) open()
    else close()
  }

  title: String(renderer.prop("title", ""))
  standardButtons: standardButtonsValue(renderer.prop("standard_buttons", ["ok", "cancel"]))
  parent: QQC.Overlay.overlay
  x: hasExplicitX ? Number(renderer.prop("x", 0))
    : (centered && parent ? Math.round((parent.width - width) / 2) : 0)
  y: hasExplicitY ? Number(renderer.prop("y", 0))
    : (centered && parent ? Math.round((parent.height - height) / 2) : 0)
  width: Number(renderer.prop("width", 480))
  height: Number(renderer.prop("height", 320))
  modal: renderer.prop("modal", true) !== false
  dim: renderer.prop("dim", modal) !== false
  focus: renderer.prop("focus", true) !== false
  closePolicy: closePolicyValue(renderer.prop("close_policy", "escape_and_outside"))
  enabled: renderer.prop("enabled", true) !== false
  padding: Number(renderer.prop("padding", Style.spacing.lg))
  font.family: String(renderer.prop("font_family", renderer.fontFamily))
  font.pixelSize: Number(renderer.prop("font_size", Style.font.body))

  background: Rectangle {
    color: renderer.prop("background", Color.background)
    radius: Number(renderer.prop("radius", Style.cornerRadius))
    border.width: String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0
    border.color: renderer.prop("border_color", "transparent")
  }

  contentItem: Loader {
    sourceComponent: dialogRoot.contentLayout === "row" ? rowContent
      : (dialogRoot.contentLayout === "stack" ? stackContent : columnContent)
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
    Item { Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent } }
  }

  Component.onCompleted: syncOpenState()
  onRequestedOpenChanged: syncOpenState()
  onAccepted: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "accept", {})
  onRejected: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "reject", {})
  onApplied: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "apply", {})
  onReset: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "reset", {})
  onDiscarded: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "discard", {})
  onHelpRequested: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "help", {})
  onOpened: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "open", {})
  onClosed: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "close", {})
  onAboutToShow: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "about_to_show", {})
  onAboutToHide: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "about_to_hide", {})
  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
  onActiveFocusChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    activeFocus ? "focus" : "blur", {})
}
