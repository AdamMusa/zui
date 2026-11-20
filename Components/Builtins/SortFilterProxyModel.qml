import QtQuick

// There is no SortFilterProxyModel in QtQml.Models. Naming this file after
// the type it wanted made the name resolve to this very file, so the adapter
// instantiated itself without end and hung the window on any page that used
// it. Filtering and sorting are done here instead, over a plain ListModel,
// which is all this component ever exposed to Ruby anyway.
Item {
  id: proxyRoot
  property var renderer: null
  property alias model: rows

  function matches(row, needle, field, sensitive) {
    if (needle === "") return true
    var value = String(row[field] === undefined ? "" : row[field])
    return sensitive ? value.indexOf(needle) >= 0
      : value.toLowerCase().indexOf(needle.toLowerCase()) >= 0
  }

  function compare(left, right, field, sensitive) {
    var first = left[field]
    var second = right[field]
    if (typeof first === "number" && typeof second === "number") return first - second
    var one = String(first === undefined ? "" : first)
    var other = String(second === undefined ? "" : second)
    if (!sensitive) { one = one.toLowerCase(); other = other.toLowerCase() }
    return one < other ? -1 : (one > other ? 1 : 0)
  }

  function rebuild() {
    var items = renderer ? renderer.prop("items", []) : []
    var needle = String(renderer ? renderer.prop("filter", "") : "")
    var field = String(renderer ? renderer.prop("filter_field", "value") : "value")
    var sensitive = renderer && renderer.prop("filter_case_sensitive", false) === true
    var sortField = String(renderer ? renderer.prop("sort_field", "") : "")
    var descending = String(renderer ? renderer.prop("sort_order", "ascending") : "ascending") === "descending"
    var sortSensitive = renderer && renderer.prop("sort_case_sensitive", false) === true

    var kept = []
    for (var index = 0; index < items.length; index++) {
      var item = items[index]
      var row = item !== null && typeof item === "object" && !Array.isArray(item) ? item : { value: item }
      if (matches(row, needle, field, sensitive)) kept.push(row)
    }
    if (sortField !== "")
      kept.sort(function(left, right) {
        var order = proxyRoot.compare(left, right, sortField, sortSensitive)
        return descending ? -order : order
      })

    rows.clear()
    for (var position = 0; position < kept.length; position++) rows.append(kept[position])
    if (!renderer) return
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "count_change", { value: rows.count })
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { count: rows.count })
  }

  ListModel { id: rows }

  Component.onCompleted: rebuild()
  Connections {
    target: renderer
    function onNodeChanged() {
      if (proxyRoot.renderer.prop("dynamic", true) !== false) proxyRoot.rebuild()
    }
  }
}
