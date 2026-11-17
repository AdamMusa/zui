import QtQuick

// Zui-native, not a Qt passthrough: Qt 6 exposes no sort/filter proxy to QML
// (QSortFilterProxyModel is C++ only), so the filtering and ordering happen
// here over the rows Ruby declared, and the result is a real ListModel.
//
// An earlier version named a SortFilterProxyModel and a StringSorter that no
// Qt QML module provides. The unqualified name resolved back to this file
// through the implicit directory import, so the component failed to load at
// all with "SortFilterProxyModel is instantiated recursively".
Item {
  id: proxyRoot

  required property var renderer
  property alias model: nativeModel
  property string handledRequestKey: ""

  implicitWidth: 0
  implicitHeight: 0
  visible: false

  function sourceRows() {
    var items = renderer.prop("items", [])
    if (!Array.isArray(items)) return []
    var rows = []
    for (var index = 0; index < items.length; index++) {
      var item = items[index]
      rows.push(item !== null && typeof item === "object" && !Array.isArray(item)
        ? item : { value: item })
    }
    return rows
  }

  function fieldValue(row, field) {
    var value = row[field]
    return value === undefined || value === null ? "" : value
  }

  function accepts(row) {
    var requested = String(renderer.prop("filter", ""))
    if (requested === "") return true
    var field = String(renderer.prop("filter_field", "value"))
    var value = String(fieldValue(row, field))
    if (renderer.prop("filter_case_sensitive", false) === true) {
      return value.indexOf(requested) >= 0
    }
    return value.toLowerCase().indexOf(requested.toLowerCase()) >= 0
  }

  function comparator() {
    var field = String(renderer.prop("sort_field", ""))
    var descending = String(renderer.prop("sort_order", "ascending")) === "descending"
    var sensitive = renderer.prop("sort_case_sensitive", false) === true
    return function(left, right) {
      var first = fieldValue(left, field)
      var second = fieldValue(right, field)
      var order = 0
      if (typeof first === "number" && typeof second === "number") {
        order = first - second
      } else {
        var firstText = sensitive ? String(first) : String(first).toLowerCase()
        var secondText = sensitive ? String(second) : String(second).toLowerCase()
        order = firstText < secondText ? -1 : (firstText > secondText ? 1 : 0)
      }
      return descending ? -order : order
    }
  }

  function requestKey() {
    return [JSON.stringify(renderer.prop("items", [])), String(renderer.prop("filter", "")),
      String(renderer.prop("filter_field", "")),
      String(renderer.prop("filter_case_sensitive", false)),
      String(renderer.prop("sort_field", "")), String(renderer.prop("sort_order", "")),
      String(renderer.prop("sort_case_sensitive", false)),
      String(renderer.prop("revision", 0))].join("\u001f")
  }

  function rebuild() {
    var key = requestKey()
    if (key === handledRequestKey) return
    handledRequestKey = key

    var rows = sourceRows().filter(accepts)
    if (String(renderer.prop("sort_field", "")) !== "") rows.sort(comparator())

    nativeModel.clear()
    for (var index = 0; index < rows.length; index++) nativeModel.append(rows[index])

    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "count_change", { value: nativeModel.count })
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "change", { count: nativeModel.count, values: rows })
  }

  ListModel {
    // A derived view: Ruby can change the shape and the types of the rows it
    // declares, and a plain ListModel fixes a role's type on first append
    // ("Can't assign to existing role of different type") because clear()
    // does not drop its roles.
    id: nativeModel
    dynamicRoles: true
  }

  Component.onCompleted: rebuild()
  Connections { target: renderer; function onNodeChanged() { proxyRoot.rebuild() } }
}
