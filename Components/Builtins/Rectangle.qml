import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Rectangle {
  required property var renderer
      readonly property int pad: Number(renderer.prop("padding", 0))
      implicitWidth: Number(renderer.prop("width", contentColumn.implicitWidth + pad * 2))
      implicitHeight: Number(renderer.prop("height", contentColumn.implicitHeight + pad * 2))
      color: renderer.prop("color", "transparent")
      radius: Number(renderer.prop("radius", 0))
      border.color: renderer.prop("border_color", "transparent")
      border.width: Number(renderer.prop("border_width", 0))
      Column {
        id: contentColumn
        anchors.centerIn: parent
        Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
      }
    }
