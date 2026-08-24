import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

QQC.RadioButton {
  required property var renderer
      id: nativeRadioButton
      text: String(renderer.prop("label", ""))
      checked: renderer.prop("checked", false) === true
      enabled: renderer.prop("enabled", true) !== false
      spacing: Number(renderer.prop("spacing", 8))
      indicator: Rectangle {
        implicitWidth: Number(renderer.prop("indicator_size", 20))
        implicitHeight: implicitWidth
        x: nativeRadioButton.leftPadding
        y: nativeRadioButton.topPadding + (nativeRadioButton.availableHeight - height) / 2
        radius: width / 2
        color: renderer.prop("background", "transparent")
        border.width: Style.normalBorderWidth
        border.color: nativeRadioButton.checked ? renderer.prop("accent", Color.accent) : renderer.prop("foreground", renderer.foreground)
        Rectangle {
          anchors.centerIn: parent
          width: parent.width * 0.5
          height: width
          radius: width / 2
          visible: nativeRadioButton.checked
          color: renderer.prop("accent", Color.accent)
        }
      }
      contentItem: Text {
        leftPadding: nativeRadioButton.indicator.width + nativeRadioButton.spacing
        text: nativeRadioButton.text
        textFormat: Text.PlainText
        color: renderer.prop("foreground", renderer.foreground)
        font.family: String(renderer.prop("font_family", renderer.fontFamily))
        font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
        verticalAlignment: Text.AlignVCenter
      }
      onClicked: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", { value: renderer.prop("value", null) })
      onToggled: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: checked, option: renderer.prop("value", null) })
      onHoveredChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", { value: hovered })
    }
