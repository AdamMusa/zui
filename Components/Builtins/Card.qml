import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

ZuiControls.BorderSurface {
  required property var renderer
      readonly property int pad: Number(renderer.prop("padding", Style.space(16)))
      implicitWidth: cardContent.implicitWidth + pad * 2
      implicitHeight: cardContent.implicitHeight + pad * 2
      color: renderer.prop("color", Color.popups.background)
      radius: Number(renderer.prop("radius", Style.cornerRadius))
      borderSpec: Border.controlSpec("normal", renderer.prop("border_color", renderer.foreground), renderer.prop("accent", Color.accent))
      Column {
        id: cardContent
        anchors.centerIn: parent
        spacing: Number(renderer.prop("spacing", Style.spacing.panelGap))
        Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
      }
    }
