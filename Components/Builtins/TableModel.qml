import QtQuick
import Qt.labs.qmlmodels

Item {
  id: tableModelRoot

  required property var renderer
  property var model: null
  property string handledRequestKey: ""
  property var appliedColumns: []

  readonly property var roleKeys: ["display", "decoration", "edit", "tool_tip", "status_tip",
    "whats_this", "font", "text_alignment", "background", "foreground", "check_state",
    "accessible_text", "accessible_description", "size_hint"]
  readonly property var roleProperties: ({
    display: "display", decoration: "decoration", edit: "edit", tool_tip: "toolTip",
    status_tip: "statusTip", whats_this: "whatsThis", font: "font",
    text_alignment: "textAlignment", background: "background", foreground: "foreground",
    check_state: "checkState", accessible_text: "accessibleText",
    accessible_description: "accessibleDescription", size_hint: "sizeHint"
  })

  implicitWidth: 0
  implicitHeight: 0
  visible: false

  function normalizedColumn(value) {
    if (value === null || value === undefined) return null
    if (typeof value !== "object") {
      var key = String(value)
      return key === "" ? null : { display: key, edit: key }
    }
    var spec = {}
    for (var index = 0; index < roleKeys.length; index++) {
      var role = roleKeys[index]
      if (value[role] === undefined || value[role] === null) continue
      var mapped = String(value[role])
      if (mapped !== "") spec[role] = mapped
    }
    return spec.display === undefined ? null : spec
  }

  function requestedColumns() {
    var specs = []
    var declared = renderer.prop("columns", [])
    if (Array.isArray(declared)) {
      for (var index = 0; index < declared.length; index++) {
        var spec = normalizedColumn(declared[index])
        if (spec) specs.push(spec)
      }
    }
    var children = renderer.node && Array.isArray(renderer.node.children)
      ? renderer.node.children : []
    for (var child = 0; child < children.length; child++) {
      var node = children[child]
      if (!node || String(node.type) !== "table_model_column") continue
      var childSpec = normalizedColumn(node.props || {})
      if (childSpec) specs.push(childSpec)
    }
    return specs
  }

  function sourceRows() {
    var rows = renderer.prop("rows", [])
    if (!Array.isArray(rows)) return []
    var normalized = []
    for (var index = 0; index < rows.length; index++) {
      var row = rows[index]
      normalized.push(row !== null && typeof row === "object" && !Array.isArray(row)
        ? row : { value: row })
    }
    return normalized
  }

  function requestKey() {
    return [JSON.stringify(requestedColumns()), JSON.stringify(sourceRows()),
      String(renderer.prop("revision", 0))].join("\u001f")
  }

  function publish() {
    if (!model) return
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "row_count_change",
      { value: model.rowCount })
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "column_count_change",
      { value: model.columnCount })
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", {
      rows: model.rowCount, columns: model.columnCount,
      column_specs: appliedColumns
    })
  }

  // TableModel reads its columns once, when the object completes, so a changed
  // column set needs a new model rather than an assignment to columns.
  function rebuild(specs) {
    var columns = []
    for (var index = 0; index < specs.length; index++) {
      var values = {}
      for (var role in specs[index]) values[roleProperties[role]] = specs[index][role]
      columns.push(columnFactory.createObject(tableModelRoot, values))
    }

    var previous = model
    model = null
    if (previous) previous.destroy()
    appliedColumns = specs
    model = tableFactory.createObject(tableModelRoot, { columns: columns })
  }

  function synchronize() {
    var key = requestKey()
    if (key === handledRequestKey) return
    handledRequestKey = key

    var specs = requestedColumns()
    if (specs.length === 0) {
      if (model) { model.destroy(); model = null }
      appliedColumns = []
      renderer.componentError("table_model_without_columns",
        "A table_model needs at least one column with a display key", {})
      return
    }
    if (!model || JSON.stringify(specs) !== JSON.stringify(appliedColumns)) rebuild(specs)
    // rows must be assigned from JavaScript: passed as an initial property it
    // arrives as a QVariantList, which TableModel rejects.
    model.rows = sourceRows()
    publish()
  }

  Component { id: columnFactory; TableModelColumn {} }
  Component { id: tableFactory; TableModel {} }

  Component.onCompleted: synchronize()
  Connections { target: renderer; function onNodeChanged() { tableModelRoot.synchronize() } }
}
