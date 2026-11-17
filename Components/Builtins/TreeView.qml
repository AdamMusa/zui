import QtQuick
import QtQuick.Controls as QQC
import QtQml.Models
import "../../Theme"

// Qt 6.8.3 exposes no QML-creatable hierarchical model: Qt.labs.qmlmodels
// exports TableModel, TableModelColumn, DelegateChoice and DelegateChooser and
// nothing else, so QQC.TreeView has no model it can be given from QML. This
// adapter therefore owns the hierarchy itself: it flattens the declared rows
// into the list of currently visible nodes, keeps depth, expansion state and
// the index path of every node, and renders them through TableView so that
// selection, editing, keyboard navigation and item reuse stay native.
Rectangle {
  id: treeRoot

  required property var renderer
  readonly property var sourceRows: renderer.prop("rows", [])
  readonly property var requestedColumns: renderer.prop("columns", [])
  readonly property string childrenField: String(renderer.prop("children_field", "children"))
  readonly property var effectiveColumns: inferColumns()
  readonly property real treePadding: Number(renderer.prop("padding", 0))
  readonly property var requestedExpandedPaths: renderer.prop("expanded_paths", [])
  readonly property int requestedExpandDepth: Number(renderer.prop("expand_depth", 0))
  readonly property var requestedSelectedPath: renderer.prop("selected_path", [])
  // Expansion is keyed by index path, which is what Ruby already speaks, so it
  // survives row refreshes and never depends on a flat row number.
  property var expandedKeys: ({})
  property var visibleNodes: []
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

  function cleanPath(value) {
    if (!Array.isArray(value)) return []
    var path = []
    for (var index = 0; index < value.length; index++) path.push(Number(value[index]))
    return path
  }

  function pathKey(path) { return cleanPath(path).join("/") }

  function isPathExpanded(path) { return expandedKeys[pathKey(path)] === true }

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

  // The flattening step. Every visible node carries the bookkeeping the
  // hierarchical model would otherwise have supplied: its index path, its
  // depth, whether it has children and whether it is expanded.
  function collectVisibleNodes(nodes, parentPath, depth, collected) {
    for (var index = 0; index < nodes.length; index++) {
      var node = nodes[index]
      var path = parentPath.concat([index])
      var children = nodeChildren(node)
      var expanded = children.length > 0 && isPathExpanded(path)
      collected.push({ node: node, path: path, depth: depth,
        has_children: children.length > 0, expanded: expanded })
      if (expanded) collectVisibleNodes(children, path, depth + 1, collected)
    }
    return collected
  }

  function flattenedNodes() {
    return collectVisibleNodes(Array.isArray(sourceRows) ? sourceRows : [], [], 0, [])
  }

  function rowMeta(row) {
    return row >= 0 && row < visibleNodes.length ? visibleNodes[row] : null
  }

  function rowForPath(path) {
    var key = pathKey(path)
    for (var index = 0; index < visibleNodes.length; index++)
      if (pathKey(visibleNodes[index].path) === key) return index
    return -1
  }

  function rowCellValue(row, column) {
    var meta = rowMeta(row)
    return meta === null ? null : nodeCell(meta.node, column)
  }

  function modelRow(node) {
    var item = {}
    for (var column = 0; column < effectiveColumns.length; column++) {
      var value = nodeCell(node, column)
      item["_c" + column] = value === undefined || value === null ? "" : value
    }
    return item
  }

  function normalizedRows() {
    var rows = []
    for (var index = 0; index < visibleNodes.length; index++)
      rows.push(modelRow(visibleNodes[index].node))
    return rows
  }

  // TableModel 1.0 is flat, which is exactly what the flattened node list
  // needs, and it is a real QAbstractItemModel so ItemSelectionModel, the
  // edit delegate and keyboard navigation all keep working.
  function modelSource() {
    var source = "import Qt.labs.qmlmodels 1.0\nTableModel {\n"
    for (var column = 0; column < effectiveColumns.length; column++)
      source += "  TableModelColumn { display: \"_c" + column + "\"; edit: \"_c" + column + "\" }\n"
    return source + "}"
  }

  function rebuildModel() {
    var previous = treeModel
    treeModel = null
    if (previous) previous.destroy()
    visibleNodes = flattenedNodes()
    if (effectiveColumns.length === 0) return
    // Without this the exception escapes, treeModel stays null and the tree
    // renders empty with nothing reported: exactly the silent failure the
    // framework boundary forbids.
    var created = null
    try {
      created = Qt.createQmlObject(modelSource(), treeRoot, "ZuiFlatTreeRowModel")
    } catch (error) {
      renderer.componentError("tree_model_unavailable",
        "This Qt build cannot create the Qt.labs.qmlmodels TableModel that tree_view "
          + "flattens its hierarchy into: " + String(error.message),
        { columns: effectiveColumns.length })
      return
    }
    created.rows = normalizedRows()
    treeModel = created
    Qt.callLater(syncTreeState)
  }

  function refreshRows() {
    visibleNodes = flattenedNodes()
    if (!treeModel) {
      rebuildModel()
      return
    }
    treeModel.rows = normalizedRows()
  }

  function expandRow(row) {
    var meta = rowMeta(row)
    if (meta === null || meta.has_children !== true) return
    expandedKeys[pathKey(meta.path)] = true
    meta.expanded = true
    var inserted = collectVisibleNodes(nodeChildren(meta.node), meta.path, meta.depth + 1, [])
    visibleNodes = visibleNodes.slice(0, row + 1).concat(inserted, visibleNodes.slice(row + 1))
    if (treeModel) {
      for (var index = 0; index < inserted.length; index++)
        treeModel.insertRow(row + 1 + index, modelRow(inserted[index].node))
    }
    notifyExpansion(meta.path, true)
  }

  function collapseRow(row) {
    var meta = rowMeta(row)
    if (meta === null || meta.has_children !== true) return
    delete expandedKeys[pathKey(meta.path)]
    meta.expanded = false
    var removed = 0
    while (row + 1 + removed < visibleNodes.length
      && visibleNodes[row + 1 + removed].depth > meta.depth) removed++
    visibleNodes = visibleNodes.slice(0, row + 1).concat(visibleNodes.slice(row + 1 + removed))
    if (treeModel && removed > 0) treeModel.removeRow(row + 1, removed)
    notifyExpansion(meta.path, false)
  }

  function toggleRow(row) {
    var meta = rowMeta(row)
    if (meta === null || meta.has_children !== true) return
    if (meta.expanded === true) collapseRow(row)
    else expandRow(row)
  }

  function expandCurrentRow() {
    if (renderer.prop("key_navigation_enabled", true) === false) return false
    var meta = rowMeta(treeControl.currentRow)
    if (meta === null || meta.has_children !== true || meta.expanded === true) return false
    expandRow(treeControl.currentRow)
    return true
  }

  function collapseCurrentRow() {
    if (renderer.prop("key_navigation_enabled", true) === false) return false
    var meta = rowMeta(treeControl.currentRow)
    if (meta === null || meta.has_children !== true || meta.expanded !== true) return false
    collapseRow(treeControl.currentRow)
    return true
  }

  function collectExpandablePaths(nodes, parentPath, remaining, collected) {
    if (remaining <= 0) return collected
    for (var index = 0; index < nodes.length; index++) {
      var children = nodeChildren(nodes[index])
      if (children.length === 0) continue
      var path = parentPath.concat([index])
      collected.push(path)
      collectExpandablePaths(children, path, remaining - 1, collected)
    }
    return collected
  }

  // Declared expansion is additive: it opens the requested nodes along with
  // their ancestors, and never closes what the user opened.
  function expandPaths(paths) {
    var changed = []
    for (var index = 0; index < paths.length; index++) {
      var path = cleanPath(paths[index])
      for (var depth = 1; depth <= path.length; depth++) {
        var ancestor = path.slice(0, depth)
        if (nodeChildren(sourceNode(ancestor)).length === 0) continue
        var key = pathKey(ancestor)
        if (expandedKeys[key] === true) continue
        expandedKeys[key] = true
        changed.push(ancestor)
      }
    }
    if (changed.length === 0) return false
    refreshRows()
    for (var notified = 0; notified < changed.length; notified++)
      notifyExpansion(changed[notified], true)
    return true
  }

  function applyRequestedExpansion() {
    var targets = collectExpandablePaths(Array.isArray(sourceRows) ? sourceRows : [], [],
      requestedExpandDepth, [])
    if (Array.isArray(requestedExpandedPaths)) {
      for (var index = 0; index < requestedExpandedPaths.length; index++)
        targets.push(cleanPath(requestedExpandedPaths[index]))
    }
    return expandPaths(targets)
  }

  function cellPayload(row, column, value) {
    var meta = rowMeta(row)
    return { row: row, column: column,
      path: meta === null ? [] : meta.path,
      depth: meta === null ? -1 : meta.depth,
      key: column >= 0 && column < effectiveColumns.length ? columnKey(column) : null,
      value: value,
      node: meta === null ? null : meta.node,
      expanded: meta === null ? false : meta.expanded === true }
  }

  function notifyExpansion(path, expanded) {
    var row = rowForPath(path)
    var payload = cellPayload(row, 0, nodeCell(sourceNode(cleanPath(path)), 0))
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      expanded ? "expand" : "collapse", payload)
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "expanded_change",
      expanded ? { row: row, depth: 1, expanded: true }
               : { row: row, recursively: false, expanded: false })
  }

  function commitEdit(row, column, value) {
    if (!columnEditable(column)) return false
    if (!treeModel || rowMeta(row) === null) return false
    var current = treeModel.getRow(row)
    var updated = {}
    for (var key in current) updated[key] = current[key]
    updated["_c" + column] = value
    treeModel.setRow(row, updated)
    return true
  }

  function syncTreeState() {
    if (!treeModel || effectiveColumns.length === 0) return
    applyRequestedExpansion()
    var path = cleanPath(requestedSelectedPath)
    if (path.length === 0) return
    expandPaths([path.slice(0, path.length - 1)])
    var row = rowForPath(path)
    if (row < 0) return
    var column = Math.max(0, Math.min(effectiveColumns.length - 1,
      Number(renderer.prop("selected_column", 0))))
    treeSelection.setCurrentIndex(treeModel.index(row, column), ItemSelectionModel.ClearAndSelect)
  }

  function selectionBehaviorValue(value) {
    var name = String(value || "rows")
    if (name === "none" || name === "disabled") return TableView.SelectionDisabled
    if (name === "cells") return TableView.SelectCells
    if (name === "columns") return TableView.SelectColumns
    return TableView.SelectRows
  }

  function selectionModeValue(value) {
    var name = String(value || "single")
    if (name === "contiguous") return TableView.ContiguousSelection
    if (name === "extended" || name === "multiple") return TableView.ExtendedSelection
    return TableView.SingleSelection
  }

  function editTriggersValue(value) {
    if (renderer.prop("editable", false) !== true) return TableView.NoEditTriggers
    var names = Array.isArray(value) ? value : [value || "edit_key"]
    var result = TableView.NoEditTriggers
    for (var index = 0; index < names.length; index++) {
      var name = String(names[index])
      if (name === "single_tap") result |= TableView.SingleTapped
      if (name === "double_tap") result |= TableView.DoubleTapped
      if (name === "selected_tap") result |= TableView.SelectedTapped
      if (name === "edit_key") result |= TableView.EditKeyPressed
      if (name === "any_key") result |= TableView.AnyKeyPressed
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

  TableView {
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

    // Left and right collapse and expand the current node, the way a native
    // tree does, and fall through to TableView's own navigation otherwise.
    Keys.onRightPressed: function(event) { event.accepted = treeRoot.expandCurrentRow() }
    Keys.onLeftPressed: function(event) { event.accepted = treeRoot.collapseCurrentRow() }

    delegate: QQC.ItemDelegate {
      id: treeDelegate
      required property int row
      required property int column
      required property var model
      property bool selected: false
      property bool current: false
      readonly property var nodeMeta: treeRoot.rowMeta(row)
      readonly property int nodeDepth: nodeMeta === null ? 0 : nodeMeta.depth
      readonly property bool nodeHasChildren: nodeMeta !== null && nodeMeta.has_children === true
      readonly property bool nodeExpanded: nodeMeta !== null && nodeMeta.expanded === true
      readonly property real indentation: Number(renderer.prop("indentation", 22))
      readonly property real handleWidth: column === 0 ? indentation : 0

      function refreshSelection() {
        if (!treeRoot.treeModel) {
          selected = false
          current = false
          return
        }
        var modelIndex = treeRoot.treeModel.index(row, column)
        selected = treeSelection.isSelected(modelIndex)
        current = treeSelection.currentIndex.valid
          && treeSelection.currentIndex.row === row
          && treeSelection.currentIndex.column === column
      }

      text: String(model.display === undefined || model.display === null ? "" : model.display)
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
      topPadding: 0
      bottomPadding: 0
      leftPadding: Number(renderer.prop("left_margin", Style.spacing.sm))
        + (column === 0 ? nodeDepth * indentation : 0)
      rightPadding: Number(renderer.prop("right_margin", Style.spacing.sm))

      background: Rectangle {
        color: treeDelegate.selected
          ? renderer.prop("selected_background", Color.popups.background)
          : (treeControl.alternatingRows && treeDelegate.row % 2 === 1
            ? renderer.prop("alternate_background", renderer.prop("cell_background", "transparent"))
            : renderer.prop("cell_background", "transparent"))
        border.width: treeDelegate.current ? Style.normalBorderWidth : 0
        border.color: renderer.prop("accent", Color.accent)
      }

      contentItem: Item {
        implicitHeight: nodeLabel.implicitHeight

        Text {
          id: disclosure
          width: treeDelegate.handleWidth
          height: parent.height
          visible: treeDelegate.column === 0 && treeDelegate.nodeHasChildren
          text: treeDelegate.nodeExpanded ? "\u25be" : "\u25b8"
          color: renderer.prop("muted", Color.muted)
          font.family: treeDelegate.font.family
          font.pixelSize: treeDelegate.font.pixelSize
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          Accessible.role: Accessible.Button
          Accessible.name: treeDelegate.nodeExpanded ? "Collapse" : "Expand"

          MouseArea {
            anchors.fill: parent
            enabled: disclosure.visible
            onClicked: treeRoot.toggleRow(treeDelegate.row)
          }
        }

        Text {
          id: nodeLabel
          anchors.left: parent.left
          anchors.leftMargin: treeDelegate.handleWidth
          anchors.right: parent.right
          height: parent.height
          text: treeDelegate.text
          color: treeDelegate.selected
            ? renderer.prop("selected_foreground", renderer.prop("foreground", renderer.foreground))
            : renderer.prop("foreground", renderer.foreground)
          font: treeDelegate.font
          horizontalAlignment: treeRoot.columnAlignment(treeDelegate.column)
          verticalAlignment: Text.AlignVCenter
          elide: Text.ElideRight
        }
      }

      TableView.editDelegate: FocusScope {
        width: parent.width
        height: parent.height
        TableView.onCommit: {
          if (!treeRoot.commitEdit(treeDelegate.row, treeDelegate.column, editor.text)) return
          renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "edit",
            treeRoot.cellPayload(treeDelegate.row, treeDelegate.column, editor.text))
        }
        QQC.TextField {
          id: editor
          anchors.fill: parent
          text: String(treeDelegate.model.edit === undefined
            ? treeDelegate.model.display : treeDelegate.model.edit)
          enabled: treeRoot.columnEditable(treeDelegate.column)
          focus: true
          Component.onCompleted: selectAll()
        }
      }

      onClicked: {
        if (treeRoot.treeModel)
          treeSelection.setCurrentIndex(treeRoot.treeModel.index(row, column),
            ItemSelectionModel.ClearAndSelect)
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
          "cell_click", treeRoot.cellPayload(row, column, model.display))
      }
      onDoubleClicked: {
        var payload = treeRoot.cellPayload(row, column, model.display)
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "cell_double_click", payload)
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "activate", payload)
      }
      Component.onCompleted: refreshSelection()
      onRowChanged: refreshSelection()
      onColumnChanged: refreshSelection()
      Connections {
        target: treeSelection
        function onSelectionChanged(selected, deselected) { treeDelegate.refreshSelection() }
        function onCurrentChanged(current, previous) { treeDelegate.refreshSelection() }
      }
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
      var payload = treeRoot.cellPayload(current.row, current.column,
        treeRoot.rowCellValue(current.row, current.column))
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
  onSourceRowsChanged: refreshRows()
  onChildrenFieldChanged: rebuildModel()
  onRequestedExpandedPathsChanged: applyRequestedExpansion()
  onRequestedExpandDepthChanged: applyRequestedExpansion()
  onRequestedSelectedPathChanged: syncTreeState()
  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
}
