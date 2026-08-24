import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Item {
  required property var renderer
      readonly property bool vertical: String(renderer.prop("orientation", "horizontal")) === "vertical"
      readonly property real lineLength: Number(renderer.prop("length", 240))
      readonly property real lineThickness: Number(renderer.prop("thickness", Style.normalBorderWidth))
      readonly property real leadingIndent: Number(renderer.prop("indent", 0))
      readonly property real trailingIndent: Number(renderer.prop("end_indent", 0))
      implicitWidth: vertical ? lineThickness : lineLength
      implicitHeight: vertical ? lineLength : lineThickness
      Rectangle {
        x: parent.vertical ? 0 : parent.leadingIndent
        y: parent.vertical ? parent.leadingIndent : 0
        width: parent.vertical ? parent.lineThickness : Math.max(0, parent.width - parent.leadingIndent - parent.trailingIndent)
        height: parent.vertical ? Math.max(0, parent.height - parent.leadingIndent - parent.trailingIndent) : parent.lineThickness
        color: renderer.prop("color", renderer.foreground)
        opacity: Number(renderer.prop("opacity", 0.2))
      }
    }
