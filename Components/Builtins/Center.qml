import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Item {
  required property var renderer
      readonly property int pad: Number(renderer.prop("padding", 0))
      implicitWidth: centeredContent.implicitWidth + pad * 2
      implicitHeight: centeredContent.implicitHeight + pad * 2
      Column {
        id: centeredContent
        anchors.centerIn: parent
        spacing: Number(renderer.prop("spacing", Style.spacing.panelGap))
        Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
      }
    }
