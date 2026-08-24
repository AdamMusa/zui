import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Rectangle {
  required property var renderer
      id: badgeRoot
      readonly property bool dotMode: renderer.prop("dot", false) === true
      readonly property real badgeSize: Number(renderer.prop("size", dotMode ? 8 : 20))
      readonly property real horizontalPad: Number(renderer.prop("padding", 6))
      readonly property var rawValue: renderer.prop("value", "")
      readonly property real maximum: Number(renderer.prop("maximum", 99))
      readonly property string displayValue: {
        if (dotMode) return ""
        var number = Number(rawValue)
        return rawValue !== "" && !isNaN(number) && number > maximum ? String(maximum) + "+" : String(rawValue)
      }
      implicitWidth: dotMode ? badgeSize : Math.max(Number(renderer.prop("minimum_width", badgeSize)), badgeText.implicitWidth + horizontalPad * 2)
      implicitHeight: badgeSize
      radius: height / 2
      color: renderer.prop("background", Color.accent)
      Text {
        id: badgeText
        anchors.centerIn: parent
        visible: !badgeRoot.dotMode
        text: badgeRoot.displayValue
        textFormat: Text.PlainText
        color: renderer.prop("foreground", Color.background)
        font.family: renderer.fontFamily
        font.bold: true
        font.pixelSize: Number(renderer.prop("font_size", Math.max(9, badgeRoot.height * 0.58)))
      }
      TapHandler { onTapped: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", { value: badgeRoot.rawValue }) }
    }
