import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Grid {
  required property var renderer
      columns: Number(renderer.prop("columns", 2))
      rows: Number(renderer.prop("rows", -1))
      rowSpacing: Number(renderer.prop("row_spacing", renderer.prop("spacing", Style.spacing.controlGap)))
      columnSpacing: Number(renderer.prop("column_spacing", renderer.prop("spacing", Style.spacing.controlGap)))
      Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
    }
