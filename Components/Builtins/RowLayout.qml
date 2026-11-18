import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts as Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Layouts.RowLayout {
  required property var renderer
      spacing: Number(renderer.prop("spacing", Style.spacing.controlGap))
      Repeater { model: renderer.node.children || []; delegate: renderer.layoutChildDelegateComponent }
    }
