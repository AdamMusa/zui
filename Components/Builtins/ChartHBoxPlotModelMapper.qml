import QtQuick
import QtCharts
import "Support" as Support

// A QtCharts model mapper binds a series to an item model. zui applications own
// no Qt item models, so the mapper is fed a table of row arrays through a
// Support.ChartRowModel and indexes into that. The mapper is created inside the
// series it drives, found by walking up to the zuiSeriesHost marker.
Item {
  id: root
  required property var renderer

  property var nativeMapper: null

  visible: false
  width: 0
  height: 0

  function seriesHost() {
    var item = root.parent
    while (item) {
      if (item["zuiSeriesHost"] === true) return item
      item = item.parent
    }
    return null
  }

  function modelRows() {
    var rows = renderer.prop("rows", [])
    return Array.isArray(rows) ? rows : []
  }

  function dataRows() { return root.modelRows().length }
  function dataColumns() { return rowModel.widestRow() }

  // A row wider than the model's column budget would be silently truncated, so
  // say so rather than charting part of the table.
  function validateRows() {
    var rows = root.modelRows()
    for (var index = 0; index < rows.length; index++) {
      if (!Array.isArray(rows[index]) || rows[index].length <= rowModel.columnBudget) continue
      renderer.componentError("chart_model_row_too_wide",
                              "A chart model row carries more than " + rowModel.columnBudget + " columns",
                              { columns: rows[index].length, budget: rowModel.columnBudget })
      return
    }
  }

  function attach() {
    if (root.nativeMapper) return
    var host = root.seriesHost()
    if (!host || !host.nativeSeries) return
    root.nativeMapper = mapperComponent.createObject(host.nativeSeries)
    if (root.nativeMapper) root.nativeMapper.series = host.nativeSeries
  }

  function attachOrReport() {
    root.attach()
    if (root.nativeMapper) return
    renderer.componentError("chart_model_mapper_without_series",
                            "A chart model mapper must be declared inside a chart series", {})
  }

  Support.ChartRowModel { id: rowModel; rowValues: root.modelRows() }

  Component {
    id: mapperComponent
    HBoxPlotModelMapper {
      model: rowModel
      firstBoxSetRow: Number(root.renderer.prop("first_box_set_row", 0))
      lastBoxSetRow: Number(root.renderer.prop("last_box_set_row", root.dataRows() - 1))
      firstColumn: Number(root.renderer.prop("first_column", 0))
      columnCount: Number(root.renderer.prop("column_count", root.dataColumns()))
    }
  }

  Component.onCompleted: {
    root.validateRows()
    root.attach()
    if (!root.nativeMapper) Qt.callLater(root.attachOrReport)
  }
  Connections { target: renderer; function onNodeChanged() { root.validateRows() } }
}
