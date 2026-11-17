import QtQuick
import QtGraphs
import "Support" as Support

// Feeds a 3D surface series from a table of row objects. QtGraphs reads the model
// by role name, so the rows are objects and the role properties name their keys.
// QML completes children before their parent, so an attach that finds no series
// yet is retried once the current event loop pass has finished building it.
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
      first: ItemModelSurfaceDataProxy.MultiMatchBehavior.First,
      last: ItemModelSurfaceDataProxy.MultiMatchBehavior.Last,
      average: ItemModelSurfaceDataProxy.MultiMatchBehavior.Average,
      cumulative_y: ItemModelSurfaceDataProxy.MultiMatchBehavior.CumulativeY
    }
    var behavior = behaviors[String(name)]
    return behavior === undefined ? ItemModelSurfaceDataProxy.MultiMatchBehavior.Last : behavior
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
                            "A graph_item_model_surface_data_proxy must be declared inside a graph_surface_3d_series", {})
  }

  Support.GraphItemModel { id: rowModel; rowValues: root.modelRows() }

  Component {
    id: proxyComponent
    ItemModelSurfaceDataProxy {
      itemModel: rowModel
      rowRole: String(root.renderer.prop("row_role", "row"))
      columnRole: String(root.renderer.prop("column_role", "column"))
      xPosRole: String(root.renderer.prop("x_pos_role", "x"))
      yPosRole: String(root.renderer.prop("y_pos_role", "y"))
      zPosRole: String(root.renderer.prop("z_pos_role", "z"))
      rowCategories: root.categoryList("row_categories")
      columnCategories: root.categoryList("column_categories")
      useModelCategories: root.renderer.prop("use_model_categories", false) === true
      autoRowCategories: root.renderer.prop("auto_row_categories", true) !== false
      autoColumnCategories: root.renderer.prop("auto_column_categories", true) !== false
      rowRoleReplace: String(root.renderer.prop("row_role_replace", ""))
      columnRoleReplace: String(root.renderer.prop("column_role_replace", ""))
      xPosRoleReplace: String(root.renderer.prop("x_pos_role_replace", ""))
      yPosRoleReplace: String(root.renderer.prop("y_pos_role_replace", ""))
      zPosRoleReplace: String(root.renderer.prop("z_pos_role_replace", ""))
      multiMatchBehavior: root.multiMatchFor(root.renderer.prop("multi_match_behavior", "last"))
    }
  }

  Component.onCompleted: {
    root.attach()
    if (!root.nativeProxy) Qt.callLater(root.attachOrReport)
  }
}
