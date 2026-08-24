import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Grid {
  required property var renderer
      id: nativeRadioGroup
      readonly property bool horizontal: String(renderer.prop("orientation", "vertical")) === "horizontal"
      columns: horizontal ? Math.max(1, radioOptions.count) : 1
      rows: horizontal ? 1 : Math.max(1, radioOptions.count)
      spacing: Number(renderer.prop("spacing", 10))
      QQC.ButtonGroup { id: exclusiveRadioGroup }
      Repeater {
        id: radioOptions
        model: renderer.prop("options", [])
        delegate: QQC.RadioButton {
          id: groupedRadioButton
          required property var modelData
          readonly property var optionValue: renderer.optionValue(modelData)
          text: String(renderer.optionLabel(modelData))
          checked: String(optionValue) === String(renderer.prop("value", ""))
          enabled: renderer.prop("enabled", true) !== false
          spacing: Number(renderer.prop("item_spacing", 8))
          QQC.ButtonGroup.group: exclusiveRadioGroup
          indicator: Rectangle {
            implicitWidth: Number(renderer.prop("indicator_size", 20))
            implicitHeight: implicitWidth
            radius: width / 2
            color: renderer.prop("background", "transparent")
            border.width: Style.normalBorderWidth
            border.color: groupedRadioButton.checked ? renderer.prop("accent", Color.accent) : renderer.prop("foreground", renderer.foreground)
            Rectangle {
              anchors.centerIn: parent
              width: parent.width * 0.5
              height: width
              radius: width / 2
              visible: groupedRadioButton.checked
              color: renderer.prop("accent", Color.accent)
            }
          }
          contentItem: Text {
            leftPadding: groupedRadioButton.indicator.width + groupedRadioButton.spacing
            text: groupedRadioButton.text
            textFormat: Text.PlainText
            color: renderer.prop("foreground", renderer.foreground)
            font.family: String(renderer.prop("font_family", renderer.fontFamily))
            font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
            verticalAlignment: Text.AlignVCenter
          }
          onClicked: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: optionValue, index: index })
          onHoveredChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", { value: optionValue, index: index, hovered: hovered })
        }
      }
    }
