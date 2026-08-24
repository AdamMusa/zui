import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Rectangle {
  required property var renderer
      id: chipRoot
      readonly property bool selected: renderer.prop("selected", false) === true
      readonly property bool deletable: renderer.prop("deletable", false) === true
      readonly property bool interactive: renderer.prop("enabled", true) !== false
      implicitWidth: chipRow.implicitWidth + Number(renderer.prop("horizontal_padding", 12)) * 2
      implicitHeight: Number(renderer.prop("height", 30))
      radius: Number(renderer.prop("radius", height / 2))
      color: selected ? renderer.prop("selected_background", Color.accent) : renderer.prop("background", Color.popups.background)
      border.width: Style.normalBorderWidth
      border.color: selected ? renderer.prop("accent", Color.accent) : renderer.foreground
      opacity: interactive ? 1 : 0.5
      Row {
        id: chipRow
        anchors.centerIn: parent
        spacing: Number(renderer.prop("spacing", 7))
        Text {
          visible: String(renderer.prop("icon", "")).length > 0
          text: renderer.iconGlyph(renderer.prop("icon", ""))
          textFormat: Text.PlainText
          color: chipRoot.selected ? renderer.prop("selected_foreground", Color.background) : renderer.prop("foreground", renderer.foreground)
          font.family: renderer.iconFontFamilyFor(renderer.prop("icon", ""))
          font.pixelSize: Number(renderer.prop("icon_size", Style.font.icon))
        }
        Text {
          text: String(renderer.prop("text", ""))
          textFormat: Text.PlainText
          color: chipRoot.selected ? renderer.prop("selected_foreground", Color.background) : renderer.prop("foreground", renderer.foreground)
          font.family: renderer.fontFamily
          font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
        }
        Text {
          visible: chipRoot.deletable
          text: renderer.iconGlyph("xmark")
          textFormat: Text.PlainText
          color: chipRoot.selected ? renderer.prop("selected_foreground", Color.background) : renderer.prop("foreground", renderer.foreground)
          font.family: renderer.iconFontFamily
          font.pixelSize: Number(renderer.prop("icon_size", Style.font.icon))
          MouseArea {
            anchors.fill: parent
            enabled: chipRoot.interactive
            onClicked: function(mouse) {
              mouse.accepted = true
              renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "delete", {})
            }
          }
        }
      }
      TapHandler {
        enabled: chipRoot.interactive
        onTapped: {
          renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", {})
          if (renderer.subscribed("change")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: !chipRoot.selected })
        }
      }
    }
