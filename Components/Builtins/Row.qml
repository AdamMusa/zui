import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Row {
  required property var renderer
      spacing: Number(renderer.prop("spacing", Style.spacing.controlGap))

      Repeater {
        model: renderer.node && Array.isArray(renderer.node.children) ? renderer.node.children : []
        delegate: renderer.rowChildDelegateComponent
      }
    }
