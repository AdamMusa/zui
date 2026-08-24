import QtQuick
import QtQuick.Controls as QQC
import QtQml.Models
import "../../Theme"

Rectangle {
  id: tableRoot

  required property var renderer
  readonly property var sourceRows: renderer.prop("rows", [])
  readonly property var requestedColumns: renderer.prop("columns", [])
  readonly property var effectiveColumns: inferColumns()
  readonly property real tablePadding: Number(renderer.prop("padding", 0))
  property var tableModel: null

  function inferColumns() {
    if (requestedColumns && requestedColumns.length > 0) return requestedColumns
    if (!sourceRows || sourceRows.length === 0) return []
    var first = sourceRows[0]
    if (Array.isArray(first)) {
      var arrayColumns = []
      for (var index = 0; index < first.length; index++) arrayColumns.push(String(index + 1))
      return arrayColumns
    }
    if (first !== null && typeof first === "object") return Object.keys(first)
    return ["Value"]
  }

  function columnProperty(column, name, fallback) {
    if (column !== null && typeof column === "object" && !Array.isArray(column)) {
      var value = column[name]
      return value === undefined || value === null ? fallback : value
    }
    return fallback
  }

  function columnKey(index) {
    var column = effectiveColumns[index]
    if (column !== null && typeof column === "object" && !Array.isArray(column))
      return String(column.key === undefined ? (column.field === undefined ? index : column.field) : column.key)
    if (Array.isArray(sourceRows[0])) return index
    return String(column)
  }

  function columnLabel(index) {
    var column = effectiveColumns[index]
    if (column !== null && typeof column === "object" && !Array.isArray(column))
      return String(column.label === undefined ? columnKey(index) : column.label)
    return String(column)
  }

  function columnWidth(index) {
    return Number(columnProperty(effectiveColumns[index], "width",
      renderer.prop("column_width", 160)))
  }

  function columnAlignment(index) {
    var name = String(columnProperty(effectiveColumns[index], "alignment", "left"))
    if (name === "center") return Text.AlignHCenter
    if (name === "right" || name === "end") return Text.AlignRight
    return Text.AlignLeft
  }

  function columnEditable(index) {
    return renderer.prop("editable", false) === true
      && columnProperty(effectiveColumns[index], "editable", true) !== false
  }

  function cellValue(row, column) {
    if (row < 0 || row >= sourceRows.length) return null
    var rowData = sourceRows[row]
    if (Array.isArray(rowData)) return rowData[column]
    if (rowData !== null && typeof rowData === "object") return rowData[columnKey(column)]
    return column === 0 ? rowData : null
  }

  function normalizedRows() {
    var normalized = []
    for (var row = 0; row < sourceRows.length; row++) {
      var item = {}
      for (var column = 0; column < effectiveColumns.length; column++)
        item["_c" + column] = cellValue(row, column)
      normalized.push(item)
    }
    return normalized
  }

  function modelSource() {
    var source = "import Qt.labs.qmlmodels 1.0\nTableModel {\n"
    for (var column = 0; column < effectiveColumns.length; column++) {
      source += "  TableModelColumn { display: \"_c" + column
        + "\"; edit: \"_c" + column + "\" }\n"
    }
    return source + "}"
  }

  function rebuildModel() {
    var previous = tableModel
    tableModel = null
    if (previous) previous.destroy()
    if (effectiveColumns.length === 0) return
    var created = Qt.createQmlObject(modelSource(), tableRoot, "ZuiDynamicTableModel")
    created.rows = normalizedRows()
    tableModel = created
    Qt.callLater(syncSelection)
  }

  function syncRows() {
    if (!tableModel) {
      rebuildModel()
      return
    }
    tableModel.rows = normalizedRows()
    Qt.callLater(syncSelection)
  }

  function syncSelection() {
    if (!tableModel || sourceRows.length === 0 || effectiveColumns.length === 0) return
    var row = Math.max(0, Math.min(sourceRows.length - 1,
      Number(renderer.prop("selected_row", 0))))
    var column = Math.max(0, Math.min(effectiveColumns.length - 1,
      Number(renderer.prop("selected_column", 0))))
    tableSelection.setCurrentIndex(tableModel.index(row, column), ItemSelectionModel.ClearAndSelect)
  }

  function selectionBehaviorValue(value) {
    var name = String(value || "cells")
    if (name === "none" || name === "disabled") return TableView.SelectionDisabled
    if (name === "rows") return TableView.SelectRows
    if (name === "columns") return TableView.SelectColumns
    return TableView.SelectCells
  }

  function selectionModeValue(value) {
    var name = String(value || "single")
    if (name === "contiguous") return TableView.ContiguousSelection
    if (name === "extended" || name === "multiple") return TableView.ExtendedSelection
    return TableView.SingleSelection
  }

  function editTriggersValue(value) {
    if (renderer.prop("editable", false) !== true) return TableView.NoEditTriggers
    var names = Array.isArray(value) ? value : [value || "double_tap_and_key"]
    var result = TableView.NoEditTriggers
    for (var index = 0; index < names.length; index++) {
      var name = String(names[index])
      if (name === "single_tap") result |= TableView.SingleTapped
      if (name === "double_tap" || name === "double_tap_and_key") result |= TableView.DoubleTapped
      if (name === "selected_tap") result |= TableView.SelectedTapped
      if (name === "edit_key" || name === "double_tap_and_key") result |= TableView.EditKeyPressed
      if (name === "any_key") result |= TableView.AnyKeyPressed
    }
    return result
  }

  function cellPayload(row, column, value) {
    return {
      row: row,
      column: column,
      key: column >= 0 && column < effectiveColumns.length ? columnKey(column) : null,
      value: value,
      row_data: row >= 0 && row < sourceRows.length ? sourceRows[row] : null
    }
  }

  implicitWidth: Number(renderer.prop("width", 720))
  implicitHeight: Number(renderer.prop("height", 440))
  color: renderer.prop("background", Color.background)
  radius: Number(renderer.prop("radius", Style.cornerRadius))
  border.width: String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0
  border.color: renderer.prop("border_color", "transparent")
  enabled: renderer.prop("enabled", true) !== false
  clip: renderer.prop("clip", true) !== false
  Accessible.name: String(renderer.prop("accessible_name", "Table"))
  Accessible.role: Accessible.Table

  ItemSelectionModel {
    id: tableSelection
    model: tableRoot.tableModel
  }

  Rectangle {
    id: headerClip
    x: tableRoot.tablePadding
    y: tableRoot.tablePadding
    width: Math.max(0, parent.width - tableRoot.tablePadding * 2)
    height: renderer.prop("show_header", true) !== false
      ? Number(renderer.prop("header_height", 42)) : 0
    visible: height > 0
    color: renderer.prop("header_background", Color.popups.background)
    clip: true

    Row {
      x: -tableControl.contentX
      height: parent.height
      Repeater {
        model: tableRoot.effectiveColumns
        Rectangle {
          required property int index
          width: tableRoot.columnWidth(index)
          height: headerClip.height
          color: "transparent"
          border.width: Style.normalBorderWidth
          border.color: renderer.prop("grid_color", Qt.rgba(renderer.foreground.r,
            renderer.foreground.g, renderer.foreground.b, 0.18))
          Text {
            anchors.fill: parent
            anchors.leftMargin: Style.spacing.md
            anchors.rightMargin: Style.spacing.md
            text: tableRoot.columnLabel(index)
            color: renderer.prop("header_foreground", renderer.prop("foreground", renderer.foreground))
            font.family: String(renderer.prop("font_family", renderer.fontFamily))
            font.pixelSize: Number(renderer.prop("header_size", Style.font.body))
            font.bold: true
            horizontalAlignment: tableRoot.columnAlignment(index)
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
          }
        }
      }
    }
  }

  TableView {
    id: tableControl
    x: tableRoot.tablePadding
    y: tableRoot.tablePadding + headerClip.height
    width: Math.max(0, parent.width - tableRoot.tablePadding * 2)
    height: Math.max(0, parent.height - tableRoot.tablePadding * 2 - headerClip.height)
    model: tableRoot.tableModel
    selectionModel: tableSelection
    selectionBehavior: tableRoot.selectionBehaviorValue(renderer.prop("selection_behavior", "cells"))
    selectionMode: tableRoot.selectionModeValue(renderer.prop("selection_mode", "single"))
    editTriggers: tableRoot.editTriggersValue(renderer.prop("edit_triggers", "double_tap_and_key"))
    alternatingRows: renderer.prop("alternating_rows", true) !== false
    animate: renderer.prop("animate", true) !== false
    reuseItems: renderer.prop("reuse_items", true) !== false
    keyNavigationEnabled: renderer.prop("key_navigation_enabled", true) !== false
    pointerNavigationEnabled: renderer.prop("pointer_navigation_enabled", true) !== false
    interactive: renderer.prop("interactive", true) !== false
    clip: true
    focus: true
    rowSpacing: Number(renderer.prop("row_spacing", 1))
    columnSpacing: Number(renderer.prop("column_spacing", 1))
    rowHeightProvider: function(row) { return Number(renderer.prop("row_height", 42)) }
    columnWidthProvider: function(column) { return tableRoot.columnWidth(column) }

    delegate: QQC.ItemDelegate {
      id: cellDelegate
      required property int row
      required property int column
      required property var model
      property bool selected: false
      property bool current: false

      function refreshSelection() {
        if (!tableRoot.tableModel) {
          selected = false
          current = false
          return
        }
        var modelIndex = tableRoot.tableModel.index(row, column)
        selected = tableSelection.isSelected(modelIndex)
        current = tableSelection.currentIndex.valid
          && tableSelection.currentIndex.row === row
          && tableSelection.currentIndex.column === column
      }

      text: String(model.display === undefined || model.display === null ? "" : model.display)
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
      padding: Style.spacing.md

      background: Rectangle {
        color: cellDelegate.selected
          ? renderer.prop("selected_background", Color.popups.background)
          : (tableControl.alternatingRows && cellDelegate.row % 2 === 1
            ? renderer.prop("alternate_background", renderer.prop("cell_background", "transparent"))
            : renderer.prop("cell_background", "transparent"))
        border.width: cellDelegate.current ? Style.normalBorderWidth : 0
        border.color: renderer.prop("accent", Color.accent)
      }

      contentItem: Text {
        text: cellDelegate.text
        color: cellDelegate.selected
          ? renderer.prop("selected_foreground", renderer.prop("foreground", renderer.foreground))
          : renderer.prop("foreground", renderer.foreground)
        font: cellDelegate.font
        horizontalAlignment: tableRoot.columnAlignment(cellDelegate.column)
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
      }

      TableView.editDelegate: FocusScope {
        width: parent.width
        height: parent.height

        TableView.onCommit: {
          if (!tableRoot.columnEditable(cellDelegate.column)) return
          var index = tableRoot.tableModel.index(cellDelegate.row, cellDelegate.column)
          if (tableRoot.tableModel.setData(index, editor.text, Qt.EditRole)) {
            renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "edit",
              tableRoot.cellPayload(cellDelegate.row, cellDelegate.column, editor.text))
          }
        }

        QQC.TextField {
          id: editor
          anchors.fill: parent
          text: String(cellDelegate.model.edit === undefined
            ? cellDelegate.model.display : cellDelegate.model.edit)
          enabled: tableRoot.columnEditable(cellDelegate.column)
          focus: true
          Component.onCompleted: selectAll()
        }
      }

      onClicked: {
        var modelIndex = tableRoot.tableModel.index(row, column)
        tableSelection.setCurrentIndex(modelIndex, ItemSelectionModel.ClearAndSelect)
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
          "cell_click", tableRoot.cellPayload(row, column, model.display))
      }
      onDoubleClicked: {
        var payload = tableRoot.cellPayload(row, column, model.display)
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "cell_double_click", payload)
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "activate", payload)
      }
      Component.onCompleted: refreshSelection()
      onRowChanged: refreshSelection()
      onColumnChanged: refreshSelection()
      Connections {
        target: tableSelection
        function onSelectionChanged(selected, deselected) { cellDelegate.refreshSelection() }
        function onCurrentChanged(current, previous) { cellDelegate.refreshSelection() }
      }
    }

    onRowsChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "row_count_change", { value: rows })
    onColumnsChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "column_count_change", { value: columns })
    onContentXChanged: {
      if (moving) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
        "scroll", { x: contentX, y: contentY })
    }
    onContentYChanged: {
      if (moving) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
        "scroll", { x: contentX, y: contentY })
    }
    onMovementStarted: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "movement_start", { x: contentX, y: contentY })
    onMovementEnded: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "movement_end", { x: contentX, y: contentY })
    onActiveFocusChanged: {
      if (renderer && renderer.bridge)
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
          activeFocus ? "focus" : "blur", {})
    }
  }

  Connections {
    target: tableSelection
    function onCurrentChanged(current, previous) {
      if (!current.valid) return
      var payload = tableRoot.cellPayload(current.row, current.column,
        tableRoot.cellValue(current.row, current.column))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "current_change", payload)
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "selection_change", payload)
    }
  }

  Text {
    anchors.centerIn: tableControl
    visible: tableRoot.sourceRows.length === 0
    text: String(renderer.prop("empty_text", "No rows"))
    color: renderer.prop("muted", Color.muted)
    font.family: String(renderer.prop("font_family", renderer.fontFamily))
    font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
  }

  Component.onCompleted: rebuildModel()
  onEffectiveColumnsChanged: rebuildModel()
  onSourceRowsChanged: syncRows()
  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
}
