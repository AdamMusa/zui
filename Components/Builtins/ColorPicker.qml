import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Dialogs
import "../../Theme"

QQC.Button {
  id: picker

  required property var renderer
  readonly property color selectedColor: dialog.selectedColor

  implicitWidth: Number(renderer.prop("width", 180))
  implicitHeight: Number(renderer.prop("height", 40))
  enabled: renderer.prop("enabled", true) !== false
  onClicked: dialog.open()

  background: Rectangle {
    color: renderer.prop("background", Color.popups.background)
    radius: Number(renderer.prop("radius", Style.cornerRadius))
    border.width: Style.normalBorderWidth
    border.color: picker.activeFocus
      ? Color.accent
      : renderer.prop("border_color", renderer.prop("foreground", renderer.foreground))
    opacity: picker.down ? 0.72 : 1
  }

  contentItem: Row {
    spacing: Style.spacing.controlGap
    Rectangle {
      width: Math.max(20, picker.height - Style.spacing.controlPaddingY * 2)
      height: width
      radius: Math.min(Number(renderer.prop("radius", Style.cornerRadius)), width / 2)
      color: picker.selectedColor
      border.width: Style.normalBorderWidth
      border.color: renderer.prop("border_color", renderer.foreground)
    }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: String(renderer.prop("label", picker.selectedColor.toString()))
      textFormat: Text.PlainText
      color: renderer.prop("foreground", renderer.foreground)
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
    }
  }

  ColorDialog {
    id: dialog
    title: String(renderer.prop("title", "Choose a color"))
    selectedColor: renderer.prop("color", "#ffffff")
    visible: renderer.prop("opened", false) === true
    options: (renderer.prop("show_alpha", false) === true ? ColorDialog.ShowAlphaChannel : 0)
      | (renderer.prop("no_buttons", false) === true ? ColorDialog.NoButtons : 0)
      | (renderer.prop("native_dialog", true) === false ? ColorDialog.DontUseNativeDialog : 0)

    onSelectedColorChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "input", {
      value: selectedColor.toString()
    })
    onAccepted: {
      var value = selectedColor.toString()
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: value })
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "accept", { value: value })
    }
    onRejected: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "reject", {
      value: selectedColor.toString()
    })
    onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      visible ? "open" : "close", { value: selectedColor.toString() })
  }
}
