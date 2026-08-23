import QtQuick
import QtQuick.Controls as QQC
import QtQml.Models
import "../../Theme"

Rectangle {
  id: treeRoot

  required property var renderer
  readonly property var sourceRows: renderer.prop("rows", [])
  readonly property var requestedColumns: renderer.prop("columns", [])
  readonly property string childrenField: String(renderer.prop("children_field", "children"))
  readonly property var effectiveColumns: inferColumns()
  readonly property real treePadding: Number(renderer.prop("padding", 0))
  property var treeModel: null

  function inferColumns() {
    if (requestedColumns && requestedColumns.length > 0) return requestedColumns
    if (!sourceRows || sourceRows.length === 0) return []
    var first = sourceRows[0]
    if (Array.isArray(first)) {
      var columns = []
      for (var index = 0; index < first.length; index++) columns.push(String(index + 1))
      return columns
    }
    if (first !== null && typeof first === "object")
      return Object.keys(first).filter(function(key) { return key !== childrenField })
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
    if (sourceRows.length > 0 && Array.isArray(sourceRows[0])) return index
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
      renderer.prop("column_width", index === 0 ? 240 : 160)))
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

  function nodeChildren(node) {
    if (node === null || typeof node !== "object" || Array.isArray(node)) return []
    var children = node[childrenField]
    return Array.isArray(children) ? children : []
  }

  function nodeCell(node, column) {
    if (Array.isArray(node)) return node[column]
    if (node !== null && typeof node === "object") return node[columnKey(column)]
    return column === 0 ? node : null
  }

  function normalizeNode(node) {
    var normalized = {}
    for (var column = 0; column < effectiveColumns.length; column++)
      normalized["_c" + column] = nodeCell(node, column)
    var children = nodeChildren(node)
    if (children.length > 0) {
      normalized.rows = []
      for (var index = 0; index < children.length; index++)
        normalized.rows.push(normalizeNode(children[index]))
    }
    return normalized
  }

  function normalizedRows() {
    var rows = []
    for (var index = 0; index < sourceRows.length; index++) rows.push(normalizeNode(sourceRows[index]))
    return rows
  }

  function modelSource() {
    var source = "import Qt.labs.qmlmodels 6.10\nTreeModel {\n"
    for (var column = 0; column < effectiveColumns.length; column++)
      source += "  TableModelColumn { display: \"_c" + column + "\"; edit: \"_c" + column + "\" }\n"
    return source + "}"
  }

  function rebuildModel() {
    var previous = treeModel
    treeModel = null
    if (previous) previous.destroy()
    if (effectiveColumns.length === 0) return
    var created = Qt.createQmlObject(modelSource(), treeRoot, "ZuiDynamicTreeModel")
    created.rows = normalizedRows()
    treeModel = created
    Qt.callLater(syncTreeState)
  }

  function syncRows() {
    if (!treeModel) return rebuildModel()
    treeModel.rows = normalizedRows()
    Qt.callLater(syncTreeState)
  }

  function cleanPath(value) {
    if (!Array.isArray(value)) return []
    var path = []
    for (var index = 0; index < value.length; index++) path.push(Number(value[index]))
    return path
  }

  function sourceNode(path) {
    var rows = sourceRows
    var node = null
    for (var depth = 0; depth < path.length; depth++) {
      var row = Number(path[depth])
      if (!rows || row < 0 || row >= rows.length) return null
      node = rows[row]
      rows = nodeChildren(node)
    }
    return node
  }

  function indexPath(modelIndex) {
    var path = []
    var current = modelIndex
    while (current && current.valid) {
      path.unshift(current.row)
      current = current.parent
    }
    return path
  }

  function cellPayload(row, column, value) {
    var modelIndex = treeControl.index(row, column)
    var path = modelIndex && modelIndex.valid ? indexPath(modelIndex) : []
    return { row: row, column: column, path: path,
      depth: row >= 0 ? treeControl.depth(row) : -1,
      key: column >= 0 && column < effectiveColumns.length ? columnKey(column) : null,
      value: value, node: sourceNode(path),
      expanded: row >= 0 ? treeControl.isExpanded(row) : false }
  }

  function syncTreeState() {
    if (!treeModel || effectiveColumns.length === 0) return
    var depth = Number(renderer.prop("expand_depth", 0))
    if (depth > 0) {
      for (var rootRow = 0; rootRow < sourceRows.length; rootRow++) {
        var rootIndex = treeModel.index([rootRow], 0)
        var rootCell = treeControl.cellAtIndex(rootIndex)
        if (rootCell.y >= 0) treeControl.expandRecursively(rootCell.y, depth - 1)
      }
    }
    var expandedPaths = renderer.prop("expanded_paths", [])
    if (Array.isArray(expandedPaths)) {
      for (var index = 0; index < expandedPaths.length; index++) {
        var expandedIndex = treeModel.index(cleanPath(expandedPaths[index]), 0)
        if (!expandedIndex.valid) continue
        treeControl.expandToIndex(expandedIndex)
        var expandedCell = treeControl.cellAtIndex(expandedIndex)
        if (expandedCell.y >= 0) treeControl.expand(expandedCell.y)
      }
    }
    var path = cleanPath(renderer.prop("selected_path", []))
    if (path.length === 0) return
    var column = Math.max(0, Math.min(effectiveColumns.length - 1,
      Number(renderer.prop("selected_column", 0))))
    var selectedIndex = treeModel.index(path, column)
    if (!selectedIndex.valid) return
    treeControl.expandToIndex(selectedIndex)
    treeSelection.setCurrentIndex(selectedIndex, ItemSelectionModel.ClearAndSelect)
  }

  function selectionBehaviorValue(value) {
    var name = String(value || "rows")
    if (name === "none" || name === "disabled") return TreeView.SelectionDisabled
    if (name === "cells") return TreeView.SelectCells
    if (name === "columns") return TreeView.SelectColumns
    return TreeView.SelectRows
  }

  function selectionModeValue(value) {
    var name = String(value || "single")
    if (name === "contiguous") return TreeView.ContiguousSelection
    if (name === "extended" || name === "multiple") return TreeView.ExtendedSelection
    return TreeView.SingleSelection
  }

  function editTriggersValue(value) {
    if (renderer.prop("editable", false) !== true) return TreeView.NoEditTriggers
    var names = Array.isArray(value) ? value : [value || "edit_key"]
    var result = TreeView.NoEditTriggers
    for (var index = 0; index < names.length; index++) {
      var name = String(names[index])
      if (name === "single_tap") result |= TreeView.SingleTapped
      if (name === "double_tap") result |= TreeView.DoubleTapped
      if (name === "selected_tap") result |= TreeView.SelectedTapped
      if (name === "edit_key") result |= TreeView.EditKeyPressed
      if (name === "any_key") result |= TreeView.AnyKeyPressed
    }
    return result
  }

  implicitWidth: Number(renderer.prop("width", 720))
  implicitHeight: Number(renderer.prop("height", 440))
  color: renderer.prop("background", Color.background)
  radius: Number(renderer.prop("radius", Style.cornerRadius))
  border.width: String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0
  border.color: renderer.prop("border_color", "transparent")
  enabled: renderer.prop("enabled", true) !== false
  clip: renderer.prop("clip", true) !== false
  Accessible.name: String(renderer.prop("accessible_name", "Tree"))
  Accessible.role: Accessible.Tree

  ItemSelectionModel { id: treeSelection; model: treeRoot.treeModel }

  Rectangle {
    id: headerClip
    x: treeRoot.treePadding
    y: treeRoot.treePadding
    width: Math.max(0, parent.width - treeRoot.treePadding * 2)
    height: renderer.prop("show_header", true) !== false ? Number(renderer.prop("header_height", 42)) : 0
    visible: height > 0
    color: renderer.prop("header_background", Color.popups.background)
    clip: true

    Row {
      x: -treeControl.contentX
      height: parent.height
      Repeater {
        model: treeRoot.effectiveColumns
        Rectangle {
          required property int index
          width: treeRoot.columnWidth(index)
          height: headerClip.height
          color: "transparent"
          border.width: Style.normalBorderWidth
          border.color: renderer.prop("grid_color", Qt.rgba(renderer.foreground.r,
            renderer.foreground.g, renderer.foreground.b, 0.18))
          Text {
            anchors.fill: parent
            anchors.leftMargin: Style.spacing.md
            anchors.rightMargin: Style.spacing.md
            text: treeRoot.columnLabel(index)
            color: renderer.prop("header_foreground", renderer.prop("foreground", renderer.foreground))
            font.family: String(renderer.prop("font_family", renderer.fontFamily))
            font.pixelSize: Number(renderer.prop("header_size", Style.font.body))
            font.bold: true
            horizontalAlignment: treeRoot.columnAlignment(index)
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
          }
        }
      }
    }
  }

  TreeView {
    id: treeControl
    x: treeRoot.treePadding
    y: treeRoot.treePadding + headerClip.height
    width: Math.max(0, parent.width - treeRoot.treePadding * 2)
    height: Math.max(0, parent.height - treeRoot.treePadding * 2 - headerClip.height)
    model: treeRoot.treeModel
    selectionModel: treeSelection
    selectionBehavior: treeRoot.selectionBehaviorValue(renderer.prop("selection_behavior", "rows"))
    selectionMode: treeRoot.selectionModeValue(renderer.prop("selection_mode", "single"))
    editTriggers: treeRoot.editTriggersValue(renderer.prop("edit_triggers", "edit_key"))
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
    columnWidthProvider: function(column) { return treeRoot.columnWidth(column) }

    delegate: QQC.TreeViewDelegate {
      id: treeDelegate
      required property int column
      indentation: Number(renderer.prop("indentation", 22))
      leftMargin: Number(renderer.prop("left_margin", Style.spacing.sm))
      rightMargin: Number(renderer.prop("right_margin", Style.spacing.sm))
      text: String(model.display === undefined || model.display === null ? "" : model.display)
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("font_size", Style.font.body))

      background: Rectangle {
        color: treeDelegate.selected
          ? renderer.prop("selected_background", Color.popups.background)
          : (treeControl.alternatingRows && treeDelegate.row % 2 === 1
            ? renderer.prop("alternate_background", renderer.prop("cell_background", "transparent"))
            : renderer.prop("cell_background", "transparent"))
        border.width: treeDelegate.current ? Style.normalBorderWidth : 0
        border.color: renderer.prop("accent", Color.accent)
      }

      contentItem: Text {
        text: treeDelegate.text
        color: treeDelegate.selected
          ? renderer.prop("selected_foreground", renderer.prop("foreground", renderer.foreground))
          : renderer.prop("foreground", renderer.foreground)
        font: treeDelegate.font
        horizontalAlignment: treeRoot.columnAlignment(treeDelegate.column)
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
        visible: !treeDelegate.editing
      }

      TableView.editDelegate: FocusScope {
        width: parent.width
        height: parent.height
        TableView.onCommit: {
          if (!treeRoot.columnEditable(treeDelegate.column)) return
          var sourceIndex = treeControl.index(treeDelegate.row, treeDelegate.column)
          if (treeRoot.treeModel.setData(sourceIndex, editor.text, Qt.EditRole))
            renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "edit",
              treeRoot.cellPayload(treeDelegate.row, treeDelegate.column, editor.text))
        }
        QQC.TextField {
          id: editor
          anchors.fill: parent
          text: String(treeDelegate.model.edit === undefined ? treeDelegate.model.display : treeDelegate.model.edit)
          enabled: treeRoot.columnEditable(treeDelegate.column)
          focus: true
          Component.onCompleted: selectAll()
        }
      }

      onClicked: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
        "cell_click", treeRoot.cellPayload(row, column, model.display))
      onDoubleClicked: {
        var payload = treeRoot.cellPayload(row, column, model.display)
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "cell_double_click", payload)
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "activate", payload)
      }
    }

    onExpanded: function(row, depth) {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "expand",
        treeRoot.cellPayload(row, 0, treeRoot.treeModel.data(treeControl.index(row, 0), Qt.DisplayRole)))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "expanded_change",
        { row: row, depth: depth, expanded: true })
    }
    onCollapsed: function(row, recursively) {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "collapse",
        treeRoot.cellPayload(row, 0, treeRoot.treeModel.data(treeControl.index(row, 0), Qt.DisplayRole)))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "expanded_change",
        { row: row, recursively: recursively, expanded: false })
    }
    onRowsChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "row_count_change", { value: rows })
    onColumnsChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "column_count_change", { value: columns })
    onContentXChanged: { if (moving) renderer.bridge.sendEvent(renderer.surfaceName,
      renderer.controlId, "scroll", { x: contentX, y: contentY }) }
    onContentYChanged: { if (moving) renderer.bridge.sendEvent(renderer.surfaceName,
      renderer.controlId, "scroll", { x: contentX, y: contentY }) }
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
    target: treeSelection
    function onCurrentChanged(current, previous) {
      if (!current.valid) return
      var cell = treeControl.cellAtIndex(current)
      if (cell.y < 0) return
      var payload = treeRoot.cellPayload(cell.y, current.column,
        treeRoot.treeModel.data(current, Qt.DisplayRole))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "current_change", payload)
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "selection_change", payload)
    }
  }

  Text {
    anchors.centerIn: treeControl
    visible: treeRoot.sourceRows.length === 0
    text: String(renderer.prop("empty_text", "No nodes"))
    color: renderer.prop("muted", Color.muted)
    font.family: String(renderer.prop("font_family", renderer.fontFamily))
    font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
  }

  Component.onCompleted: rebuildModel()
  onEffectiveColumnsChanged: rebuildModel()
  onSourceRowsChanged: syncRows()
  onChildrenFieldChanged: rebuildModel()
  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
}
