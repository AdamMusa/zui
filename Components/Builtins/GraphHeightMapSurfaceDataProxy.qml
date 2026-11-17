import QtQuick
import QtGraphs

// Feeds a 3D surface series from a height map image rather than a table: the
// pixel luminance becomes the Y value. QML completes children before their
// parent, so an attach that finds no series yet is retried once the current
// event loop pass has finished building the subtree.
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
                            "A graph_height_map_surface_data_proxy must be declared inside a graph_surface_3d_series", {})
  }

  Component {
    id: proxyComponent
    HeightMapSurfaceDataProxy {
      // Qt reads the image itself, so this is a file path, not a resource URL.
      heightMapFile: String(root.renderer.prop("height_map_file", ""))
      minXValue: Number(root.renderer.prop("minimum_x", 0))
      maxXValue: Number(root.renderer.prop("maximum_x", 10))
      minYValue: Number(root.renderer.prop("minimum_y", 0))
      maxYValue: Number(root.renderer.prop("maximum_y", 10))
      minZValue: Number(root.renderer.prop("minimum_z", 0))
      maxZValue: Number(root.renderer.prop("maximum_z", 10))
      autoScaleY: root.renderer.prop("auto_scale_y", false) === true
    }
  }

  Component.onCompleted: {
    root.attach()
    if (!root.nativeProxy) Qt.callLater(root.attachOrReport)
  }
}
