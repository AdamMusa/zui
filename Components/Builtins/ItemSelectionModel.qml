import QtQuick
import QtQml.Models

Item {
  id: selectionRoot

  required property var renderer
  property alias model: sourceModel
  property alias selection: nativeSelection
  property string handledRequestKey: ""
  property bool applying: false

  implicitWidth: 0
  implicitHeight: 0
  visible: false

  function sourceItems() {
    var items = renderer.prop("items", [])
    return Array.isArray(items) ? items : []
  }

  function rowOf(value) {
    var items = sourceItems()
    var field = String(renderer.prop("key_field", ""))
    for (var index = 0; index < items.length; index++) {
      var item = items[index]
      if (field !== "" && item !== null && typeof item === "object") {
        if (item[field] === value) return index
      } else if (item === value) {
        return index
      }
    }
    var numeric = Number(value)
    return isNaN(numeric) ? -1 : Math.floor(numeric)
  }

  function requestedRows() {
    var requested = renderer.prop("selected", [])
    var values = Array.isArray(requested) ? requested : [requested]
    var rows = []
    for (var index = 0; index < values.length; index++) {
      var row = rowOf(values[index])
      if (row >= 0 && row < sourceModel.count && rows.indexOf(row) < 0) rows.push(row)
    }
    return rows.sort(function(left, right) { return left - right })
  }

  // Ruby declares the complete selection, so the mode only picks the
  // granularity Qt records it at. Incremental commands such as Toggle and
  // ClearAndSelect are imperative and would fight the declared state.
  function selectionCommand() {
    var mode = String(renderer.prop("selection_mode", "items"))
    if (mode === "rows") return ItemSelectionModel.Select | ItemSelectionModel.Rows
    if (mode === "columns") return ItemSelectionModel.Select | ItemSelectionModel.Columns
    return ItemSelectionModel.Select
  }

  function selectedRows() {
    var indexes = nativeSelection.selectedIndexes
    var rows = []
    for (var index = 0; index < indexes.length; index++) {
      var row = Number(indexes[index].row)
      if (rows.indexOf(row) < 0) rows.push(row)
    }
    return rows.sort(function(left, right) { return left - right })
  }

  function rowValue(row) {
    var items = sourceItems()
    if (row < 0 || row >= items.length) return null
    var item = items[row]
    var field = String(renderer.prop("key_field", ""))
    if (field !== "" && item !== null && typeof item === "object") return item[field]
    return item
  }

  function requestKey() {
    return [JSON.stringify(sourceItems()), JSON.stringify(renderer.prop("selected", [])),
      String(renderer.prop("current_index", -1)), String(renderer.prop("selection_mode", "")),
      String(renderer.prop("key_field", "")),
      String(renderer.prop("revision", 0))].join("\u001f")
  }

  function rebuild() {
    sourceModel.clear()
    var items = sourceItems()
    for (var index = 0; index < items.length; index++) {
      var item = items[index]
      sourceModel.append(item !== null && typeof item === "object" && !Array.isArray(item)
        ? item : { value: item })
    }
  }

  function applySelection() {
    applying = true
    var command = selectionCommand()
    var rows = requestedRows()
    nativeSelection.clearSelection()
    for (var index = 0; index < rows.length; index++) {
      nativeSelection.select(sourceModel.index(rows[index], 0), command)
    }
    var current = Math.floor(Number(renderer.prop("current_index", -1)))
    if (current >= 0 && current < sourceModel.count) {
      nativeSelection.setCurrentIndex(sourceModel.index(current, 0), ItemSelectionModel.NoUpdate)
    } else {
      nativeSelection.clearCurrentIndex()
    }
    applying = false
  }

  function publishSelection() {
    var rows = selectedRows()
    var values = []
    for (var index = 0; index < rows.length; index++) values.push(rowValue(rows[index]))
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "selection_change", { rows: rows, values: values, count: rows.length })
  }

  function publish() {
    var rows = selectedRows()
    var values = []
    for (var index = 0; index < rows.length; index++) values.push(rowValue(rows[index]))
    var current = Number(nativeSelection.currentIndex.row)
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", {
      rows: rows, values: values, current: current,
      count: sourceModel.count, has_selection: nativeSelection.hasSelection
    })
  }

  function synchronize() {
    var key = requestKey()
    if (key === handledRequestKey) return
    handledRequestKey = key
    rebuild()
    applySelection()
    publishSelection()
    publish()
  }

  ListModel {
    // Ruby owns the row shape and the model is rebuilt on every change, so
    // dynamic roles avoid a plain ListModel fixing a role's type on first
    // append while clear() keeps its roles.
    id: sourceModel
    dynamicRoles: true
  }

  ItemSelectionModel {
    id: nativeSelection
    model: sourceModel

    onSelectionChanged: {
      if (selectionRoot.applying) return
      selectionRoot.publishSelection()
    }
    onCurrentChanged: function(current, previous) {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "current_change", {
        row: Number(current.row), previous: Number(previous.row),
        value: selectionRoot.rowValue(Number(current.row))
      })
    }
  }

  Component.onCompleted: synchronize()
  Connections { target: renderer; function onNodeChanged() { selectionRoot.synchronize() } }
}
