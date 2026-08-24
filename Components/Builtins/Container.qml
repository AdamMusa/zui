import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

ZuiControls.BorderSurface {
  required property var renderer
      readonly property int innerPadding: Number(renderer.prop("padding", 0))
      implicitWidth: content.implicitWidth + innerPadding * 2
      implicitHeight: content.implicitHeight + innerPadding * 2
      color: "transparent"
      borderSpec: renderer.prop("bordered", false)
        ? Border.controlSpec("normal", renderer.foreground, Color.accent)
        : Border.none()
      radius: Style.cornerRadius

      Column {
        id: content
        anchors.centerIn: parent
        spacing: Number(renderer.prop("spacing", Style.spacing.panelGap))

        Repeater {
          model: renderer.node && Array.isArray(renderer.node.children) ? renderer.node.children : []
          delegate: renderer.childDelegateComponent
        }
      }
    }
