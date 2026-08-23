import QtQuick
import "." as Builtins

Item {
  id: dataRoot
  property var renderer: null
  implicitWidth: Number(renderer ? renderer.prop("width", 720) : 720)
  implicitHeight: Number(renderer ? renderer.prop("height", 440) : 440)

  function valueFor(row, field) {
    if (row === null || typeof row !== "object") return row
    return row[String(field || "")]
  }
  function processedRows() {
    if (!renderer) return []
    var rows = renderer.prop("rows", []).slice()
    var filter = String(renderer.prop("filter", "")).toLowerCase()
    if (filter !== "") rows = rows.filter(function(row) { return JSON.stringify(row).toLowerCase().indexOf(filter) >= 0 })
    var columns = renderer.prop("columns", [])
    var sortColumn = Number(renderer.prop("sort_column", -1))
    if (sortColumn >= 0 && sortColumn < columns.length) {
      var column = columns[sortColumn]
      var key = column && typeof column === "object" ? (column.key === undefined ? column.field : column.key) : column
      var descending = String(renderer.prop("sort_order", "ascending")) === "descending"
      rows.sort(function(left, right) {
        var a = dataRoot.valueFor(left, key); var b = dataRoot.valueFor(right, key)
        if (a === b) return 0
        var result = a === null || a === undefined ? -1 : (b === null || b === undefined ? 1 : (a < b ? -1 : 1))
        return descending ? -result : result
      })
    }
    var pageSize = Math.max(0, Number(renderer.prop("page_size", 0)))
    if (pageSize > 0) {
      var page = Math.max(1, Number(renderer.prop("page", 1)))
      rows = rows.slice((page - 1) * pageSize, page * pageSize)
    }
    return rows
  }

  QtObject {
    id: proxyRenderer
    readonly property var bridge: dataRoot.renderer ? dataRoot.renderer.bridge : null
    readonly property string surfaceName: dataRoot.renderer ? dataRoot.renderer.surfaceName : ""
    readonly property string controlId: dataRoot.renderer ? dataRoot.renderer.controlId : ""
    readonly property color foreground: dataRoot.renderer ? dataRoot.renderer.foreground : "white"
    readonly property string fontFamily: dataRoot.renderer ? dataRoot.renderer.fontFamily : ""
    function prop(name, fallback) { return name === "rows" ? dataRoot.processedRows() : dataRoot.renderer.prop(name, fallback) }
  }
  Builtins.TableView { anchors.fill: parent; renderer: proxyRenderer }

  TapHandler {
    enabled: renderer && renderer.subscribed("sort") && renderer.prop("show_header", true) !== false
    onTapped: function(eventPoint) {
      var columns = renderer.prop("columns", [])
      var x = eventPoint.position.x - Number(renderer.prop("padding", 0))
      var cursor = 0
      for (var index = 0; index < columns.length; index++) {
        var width = Number(columns[index] && columns[index].width !== undefined ? columns[index].width : renderer.prop("column_width", 160))
        if (x >= cursor && x < cursor + width) {
          var current = Number(renderer.prop("sort_column", -1))
          var order = current === index && String(renderer.prop("sort_order", "ascending")) === "ascending" ? "descending" : "ascending"
          renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "sort", { column: index, order: order })
          break
        }
        cursor += width
      }
    }
  }
}
