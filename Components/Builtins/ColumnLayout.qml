import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

ColumnLayout {
  required property var renderer
      spacing: Number(renderer.prop("spacing", Style.spacing.panelGap))
      Repeater { model: renderer.node.children || []; delegate: renderer.layoutChildDelegateComponent }
    }
