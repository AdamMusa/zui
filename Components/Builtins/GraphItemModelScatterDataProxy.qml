import QtQuick
import QtGraphs
import "Support" as Support

// Feeds a 3D scatter series from a table of row objects. QtGraphs reads the model
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
                            "A graph_item_model_scatter_data_proxy must be declared inside a graph_scatter_3d_series", {})
  }

  Support.GraphItemModel { id: rowModel; rowValues: root.modelRows() }

  Component {
    id: proxyComponent
    ItemModelScatterDataProxy {
      itemModel: rowModel
      xPosRole: String(root.renderer.prop("x_pos_role", "x"))
      yPosRole: String(root.renderer.prop("y_pos_role", "y"))
      zPosRole: String(root.renderer.prop("z_pos_role", "z"))
      rotationRole: String(root.renderer.prop("rotation_role", ""))
      xPosRoleReplace: String(root.renderer.prop("x_pos_role_replace", ""))
      yPosRoleReplace: String(root.renderer.prop("y_pos_role_replace", ""))
      zPosRoleReplace: String(root.renderer.prop("z_pos_role_replace", ""))
      rotationRoleReplace: String(root.renderer.prop("rotation_role_replace", ""))
    }
  }

  Component.onCompleted: {
    root.attach()
    if (!root.nativeProxy) Qt.callLater(root.attachOrReport)
  }
}
