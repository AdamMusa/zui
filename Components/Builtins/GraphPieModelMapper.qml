import QtQuick
import QtGraphs
import "Support" as Support

// A QtGraphs model mapper binds a series to an item model. zui applications own
// no Qt item models, so the mapper is fed a table of row arrays through the same
// Support.ChartRowModel the QtCharts mappers use, and indexes into that.
//
// QtGraphs folds QtCharts' separate H and V mappers into one type with an
// orientation, so a section is a column when horizontal and a row when vertical.
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

  function mapperOrientation(name) {
    return String(name) === "vertical" ? Qt.Vertical : Qt.Horizontal
  }

  // Horizontal mapping walks the model's columns, vertical mapping its rows, so
  // the default count follows whichever the orientation actually reads.
  function defaultCount() {
    return root.mapperOrientation(renderer.prop("orientation", "vertical")) === Qt.Vertical
      ? root.modelRows().length
      : rowModel.widestRow()
  }

  // A row wider than the model's column budget would be silently truncated, so
  // say so rather than charting part of the table.
  function validateRows() {
    var rows = root.modelRows()
    for (var index = 0; index < rows.length; index++) {
      if (!Array.isArray(rows[index]) || rows[index].length <= rowModel.columnBudget) continue
      renderer.componentError("graph_model_row_too_wide",
                              "A graph model row carries more than " + rowModel.columnBudget + " columns",
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
    renderer.componentError("graph_model_mapper_without_series",
                            "A graph model mapper must be declared inside a QtGraphs series", {})
  }

  Support.ChartRowModel { id: rowModel; rowValues: root.modelRows() }

  Component {
    id: mapperComponent
    PieModelMapper {
      model: rowModel
      orientation: root.mapperOrientation(root.renderer.prop("orientation", "vertical"))
      first: Number(root.renderer.prop("first", 0))
      count: Number(root.renderer.prop("count", root.defaultCount()))
      valuesSection: Number(root.renderer.prop("values_section", 0))
      labelsSection: Number(root.renderer.prop("labels_section", 1))
    }
  }

  Component.onCompleted: {
    root.validateRows()
    root.attach()
    if (!root.nativeMapper) Qt.callLater(root.attachOrReport)
  }
  Connections { target: renderer; function onNodeChanged() { root.validateRows() } }
}
