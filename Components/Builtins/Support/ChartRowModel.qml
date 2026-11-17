import QtQuick
import Qt.labs.qmlmodels

// QtCharts model mappers read a real QAbstractItemModel, which zui applications
// never own: their chart data arrives as node properties. This turns a table of
// row arrays into a model a mapper can index into.
//
// TableModel columns cannot be created after the model exists - pushing onto
// its columns list leaves columnCount at zero - so the column budget is
// declared here and row arrays are widened into its roles. Mappers default
// their column count to the real data width so the unused budget is never read.
TableModel {
  id: rowModel

  readonly property int columnBudget: 16
  property var rowValues: []

  function widestRow() {
    var widest = 0
    for (var index = 0; index < rowModel.rowValues.length; index++) {
      var row = rowModel.rowValues[index]
      if (Array.isArray(row)) widest = Math.max(widest, row.length)
    }
    return Math.min(widest, rowModel.columnBudget)
  }

  function refresh() {
    var source = Array.isArray(rowModel.rowValues) ? rowModel.rowValues : []
    var rows = []
    for (var index = 0; index < source.length; index++) {
      var values = source[index]
      var row = {}
      for (var column = 0; column < rowModel.columnBudget; column++) {
        var value
        if (Array.isArray(values)) value = values[column]
        else if (values !== null && typeof values === "object") value = values["c" + column]
        row["c" + column] = value === undefined || value === null ? 0 : value
      }
      rows.push(row)
    }
    rowModel.rows = rows
  }

  onRowValuesChanged: rowModel.refresh()
  Component.onCompleted: rowModel.refresh()

  TableModelColumn { display: "c0" }
  TableModelColumn { display: "c1" }
  TableModelColumn { display: "c2" }
  TableModelColumn { display: "c3" }
  TableModelColumn { display: "c4" }
  TableModelColumn { display: "c5" }
  TableModelColumn { display: "c6" }
  TableModelColumn { display: "c7" }
  TableModelColumn { display: "c8" }
  TableModelColumn { display: "c9" }
  TableModelColumn { display: "c10" }
  TableModelColumn { display: "c11" }
  TableModelColumn { display: "c12" }
  TableModelColumn { display: "c13" }
  TableModelColumn { display: "c14" }
  TableModelColumn { display: "c15" }
}
