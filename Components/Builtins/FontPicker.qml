import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Dialogs
import "../../Theme"

QQC.Button {
  id: picker

  required property var renderer
  readonly property font chosenFont: buildFont()

  function buildFont() {
    var specification = {
      family: String(renderer.prop("family", renderer.fontFamily)),
      weight: Number(renderer.prop("weight", Font.Normal)),
      italic: renderer.prop("italic", false) === true,
      underline: renderer.prop("underline", false) === true,
      strikeout: renderer.prop("strikeout", false) === true
    }
    var pointSize = Number(renderer.prop("point_size", -1))
    var pixelSize = Number(renderer.prop("pixel_size", -1))
    if (pointSize > 0) specification.pointSize = pointSize
    else if (pixelSize > 0) specification.pixelSize = pixelSize
    return Qt.font(specification)
  }

  function fontPayload(value) {
    return {
      value: value.family,
      family: value.family,
      point_size: value.pointSize,
      pixel_size: value.pixelSize,
      weight: value.weight,
      italic: value.italic,
      underline: value.underline,
      strikeout: value.strikeout
    }
  }

  implicitWidth: Number(renderer.prop("width", 240))
  implicitHeight: Number(renderer.prop("height", 44))
  enabled: renderer.prop("enabled", true) !== false
  onClicked: fontDialog.open()

  background: Rectangle {
    color: renderer.prop("background", Color.popups.background)
    radius: Number(renderer.prop("radius", Style.cornerRadius))
    border.width: Style.normalBorderWidth
    border.color: picker.activeFocus
      ? renderer.prop("accent", Color.accent)
      : renderer.prop("border_color", renderer.foreground)
    opacity: picker.down ? 0.72 : 1
  }

  contentItem: Column {
    spacing: 2
    Text {
      text: String(renderer.prop("label", ""))
      visible: text.length > 0
      color: renderer.prop("muted", Color.muted)
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("font_size", Style.font.caption))
    }
    Text {
      width: parent.width
      text: String(renderer.prop("family", renderer.prop("placeholder", "Choose a font")))
      elide: Text.ElideRight
      color: renderer.prop("foreground", renderer.foreground)
      font: picker.chosenFont
    }
  }

  FontDialog {
    id: fontDialog
    title: String(renderer.prop("title", "Choose a font"))
    selectedFont: picker.chosenFont
    visible: renderer.prop("opened", false) === true
    options: renderer.prop("native_dialog", true) === false ? FontDialog.DontUseNativeDialog : 0

    onSelectedFontChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "input", picker.fontPayload(selectedFont))
    onAccepted: {
      var payload = picker.fontPayload(selectedFont)
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", payload)
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "accept", payload)
    }
    onRejected: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "reject", {})
    onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      visible ? "open" : "close", {})
  }
}
