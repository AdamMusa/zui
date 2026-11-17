import QtQuick
import QtGraphs
import "Support" as Support

// Feeds a 3D bar series from a table of row objects. QtGraphs reads the model by
// role name, so the rows are objects and row_role/column_role/value_role name
// their keys. The proxy is assigned to the series above it; QML completes
// children before their parent, so an attach that finds no series yet is
// retried once the current event loop pass has finished building the subtree.
Item {
  id: root
  required property var renderer

  property var nativeProxy: null

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

  function categoryList(key) {
    var categories = renderer.prop(key, [])
    if (!Array.isArray(categories)) return []
    return categories.map(function(category) { return String(category) })
  }

  // QtGraphs enforces scoped enums, so the value is named through its enum.
  function multiMatchFor(name) {
    var behaviors = {
      first: ItemModelBarDataProxy.MultiMatchBehavior.First,
      last: ItemModelBarDataProxy.MultiMatchBehavior.Last,
      average: ItemModelBarDataProxy.MultiMatchBehavior.Average,
      cumulative: ItemModelBarDataProxy.MultiMatchBehavior.Cumulative
    }
    var behavior = behaviors[String(name)]
    return behavior === undefined ? ItemModelBarDataProxy.MultiMatchBehavior.Last : behavior
  }

  function attach() {
    if (root.nativeProxy) return
    var host = root.seriesHost()
    if (!host || !host.nativeSeries) return
    root.nativeProxy = proxyComponent.createObject(host.nativeSeries)
    if (root.nativeProxy) host.nativeSeries.dataProxy = root.nativeProxy
  }

  function attachOrReport() {
    root.attach()
    if (root.nativeProxy) return
    renderer.componentError("graph_data_proxy_without_series",
                            "A graph_item_model_bar_data_proxy must be declared inside a graph_bar_3d_series", {})
  }

  Support.GraphItemModel { id: rowModel; rowValues: root.modelRows() }

  Component {
    id: proxyComponent
    ItemModelBarDataProxy {
      itemModel: rowModel
      rowRole: String(root.renderer.prop("row_role", "row"))
      columnRole: String(root.renderer.prop("column_role", "column"))
      valueRole: String(root.renderer.prop("value_role", "value"))
      rotationRole: String(root.renderer.prop("rotation_role", ""))
      rowCategories: root.categoryList("row_categories")
      columnCategories: root.categoryList("column_categories")
      useModelCategories: root.renderer.prop("use_model_categories", false) === true
      autoRowCategories: root.renderer.prop("auto_row_categories", true) !== false
      autoColumnCategories: root.renderer.prop("auto_column_categories", true) !== false
      rowRoleReplace: String(root.renderer.prop("row_role_replace", ""))
      columnRoleReplace: String(root.renderer.prop("column_role_replace", ""))
      valueRoleReplace: String(root.renderer.prop("value_role_replace", ""))
      rotationRoleReplace: String(root.renderer.prop("rotation_role_replace", ""))
      multiMatchBehavior: root.multiMatchFor(root.renderer.prop("multi_match_behavior", "last"))
    }
  }

  Component.onCompleted: {
    root.attach()
    if (!root.nativeProxy) Qt.callLater(root.attachOrReport)
  }
}
