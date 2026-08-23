import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.DialogButtonBox {
  id: box

  required property var renderer

  function standardButtonValue(name) {
    var key = String(name || "").toLowerCase()
    if (key === "ok") return QQC.DialogButtonBox.Ok
    if (key === "save") return QQC.DialogButtonBox.Save
    if (key === "save_all") return QQC.DialogButtonBox.SaveAll
    if (key === "open") return QQC.DialogButtonBox.Open
    if (key === "yes") return QQC.DialogButtonBox.Yes
    if (key === "yes_to_all") return QQC.DialogButtonBox.YesToAll
    if (key === "no") return QQC.DialogButtonBox.No
    if (key === "no_to_all") return QQC.DialogButtonBox.NoToAll
    if (key === "abort") return QQC.DialogButtonBox.Abort
    if (key === "retry") return QQC.DialogButtonBox.Retry
    if (key === "ignore") return QQC.DialogButtonBox.Ignore
    if (key === "close") return QQC.DialogButtonBox.Close
    if (key === "cancel") return QQC.DialogButtonBox.Cancel
    if (key === "discard") return QQC.DialogButtonBox.Discard
    if (key === "help") return QQC.DialogButtonBox.Help
    if (key === "apply") return QQC.DialogButtonBox.Apply
    if (key === "reset") return QQC.DialogButtonBox.Reset
    if (key === "restore_defaults") return QQC.DialogButtonBox.RestoreDefaults
    return QQC.DialogButtonBox.NoButton
  }

  function standardButtonsValue(values) {
    var result = QQC.DialogButtonBox.NoButton
    var buttons = Array.isArray(values) ? values : [values]
    for (var index = 0; index < buttons.length; index++) result |= standardButtonValue(buttons[index])
    return result
  }

  function roleValue(value) {
    var key = String(value || "action").toLowerCase()
    if (key === "accept") return QQC.DialogButtonBox.AcceptRole
    if (key === "reject") return QQC.DialogButtonBox.RejectRole
    if (key === "destructive") return QQC.DialogButtonBox.DestructiveRole
    if (key === "help") return QQC.DialogButtonBox.HelpRole
    if (key === "yes") return QQC.DialogButtonBox.YesRole
    if (key === "no") return QQC.DialogButtonBox.NoRole
    if (key === "reset") return QQC.DialogButtonBox.ResetRole
    if (key === "apply") return QQC.DialogButtonBox.ApplyRole
    return QQC.DialogButtonBox.ActionRole
  }

  function alignmentValue(value) {
    var key = String(value || "right")
    if (key === "left" || key === "start") return Qt.AlignLeft
    if (key === "center") return Qt.AlignHCenter
    if (key === "justify") return Qt.AlignJustify
    return Qt.AlignRight
  }

  function buttonPayload(button) {
    return {
      text: button ? button.text : "",
      role: button ? buttonRole(button) : QQC.DialogButtonBox.InvalidRole,
      standard_button: button ? standardButton(button) : QQC.DialogButtonBox.NoButton
    }
  }

  standardButtons: standardButtonsValue(renderer.prop("buttons", []))
  alignment: renderer.prop("centered", false) === true
    ? Qt.AlignHCenter : alignmentValue(renderer.prop("alignment", "right"))
  position: String(renderer.prop("position", "footer")) === "header"
    ? QQC.DialogButtonBox.Header : QQC.DialogButtonBox.Footer
  spacing: Number(renderer.prop("spacing", Style.spacing.sm))
  implicitWidth: Number(renderer.prop("width", contentItem ? contentItem.implicitWidth : 240))
  implicitHeight: Number(renderer.prop("height", contentItem ? contentItem.implicitHeight : 44))
  enabled: renderer.prop("enabled", true) !== false

  background: Rectangle {
    color: renderer.prop("background", "transparent")
  }

  contentItem: ListView {
    implicitWidth: orientation === ListView.Horizontal ? contentWidth : widestItem
    implicitHeight: orientation === ListView.Vertical ? contentHeight : tallestItem
    model: box.contentModel
    spacing: box.spacing
    orientation: String(renderer.prop("orientation", "horizontal")) === "vertical"
      ? ListView.Vertical : ListView.Horizontal
    boundsBehavior: Flickable.StopAtBounds
    snapMode: ListView.SnapToItem
    readonly property real widestItem: {
      var result = 0
      for (var index = 0; index < count; index++) {
        var child = itemAtIndex(index)
        if (child) result = Math.max(result, child.implicitWidth)
      }
      return result
    }
    readonly property real tallestItem: {
      var result = 0
      for (var index = 0; index < count; index++) {
        var child = itemAtIndex(index)
        if (child) result = Math.max(result, child.implicitHeight)
      }
      return result
    }
  }

  delegate: QQC.Button {
    id: standardDelegate
    font.family: String(renderer.prop("font_family", renderer.fontFamily))
    font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
    palette.buttonText: renderer.prop("foreground", renderer.foreground)
    palette.highlight: renderer.prop("accent", Color.accent)
  }

  Repeater {
    model: renderer.prop("custom_buttons", [])
    delegate: QQC.Button {
      required property var modelData
      text: String(modelData && modelData.text !== undefined ? modelData.text : modelData)
      QQC.DialogButtonBox.buttonRole: box.roleValue(modelData && modelData.role !== undefined ? modelData.role : "action")
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
      palette.buttonText: renderer.prop("foreground", renderer.foreground)
      palette.highlight: renderer.prop("accent", Color.accent)
    }
  }

  onClicked: function(button) {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", box.buttonPayload(button))
  }
  onAccepted: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "accept", {})
  onRejected: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "reject", {})
  onHelpRequested: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "help", {})
}
