import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Rectangle {
  required property var renderer
      id: badgeRoot
      function labelText() {
        if (renderer.prop("dot", false) === true) return ""
        var raw = renderer.prop("value", "")
        var number = Number(raw)
        var maximum = Number(renderer.prop("maximum", 99))
        return raw !== "" && !isNaN(number) && number > maximum ? String(maximum) + "+" : String(raw)
      }
      implicitWidth: renderer.prop("dot", false) === true
        ? Number(renderer.prop("size", 8))
        : Math.max(Number(renderer.prop("minimum_width", 20)), Math.ceil(labelText().length
          * Number(renderer.prop("font_size", 12)) * 0.62 + Number(renderer.prop("padding", 6)) * 2))
      implicitHeight: Number(renderer.prop("size", renderer.prop("dot", false) === true ? 8 : 20))
      radius: Number(renderer.prop("size", renderer.prop("dot", false) === true ? 8 : 20)) / 2
      color: renderer.prop("background", Color.accent)
      Text {
        id: badgeText
        anchors.centerIn: parent
        visible: renderer.prop("dot", false) !== true
        text: badgeRoot.labelText()
        textFormat: Text.PlainText
        color: renderer.prop("foreground", Color.background)
        font.family: renderer.fontFamily
        font.bold: true
        font.pixelSize: Number(renderer.prop("font_size", 12))
      }
      TapHandler { onTapped: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", { value: renderer.prop("value", "") }) }
    }
