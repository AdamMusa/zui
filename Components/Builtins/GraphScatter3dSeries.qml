import QtQuick
import QtGraphs

// A QtGraphs 3D series is handed to the graph through addSeries(), so the
// adapter stays an invisible item, builds the native series with real bindings
// and gives it to the Scatter3D above it.
Item {
  id: root
  required property var renderer

  readonly property bool zuiSeriesHost: true
  property var nativeSeries: null
  property var ownerGraph: null

  visible: false
  width: 0
  height: 0

  function graphsHost() {
    var item = root.parent
    while (item) {
      if (item["zuiGraphsHost"] === true) return item
      item = item.parent
    }
    return null
  }

  function send(name, payload) {
    if (renderer.subscribed(name)) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }

  // QtGraphs enforces scoped enums, so every value is named through its enum.
  function meshFor(name) {
    var meshes = {
      user_defined: Scatter3DSeries.Mesh.UserDefined,
      bar: Scatter3DSeries.Mesh.Bar,
      cube: Scatter3DSeries.Mesh.Cube,
      pyramid: Scatter3DSeries.Mesh.Pyramid,
      cone: Scatter3DSeries.Mesh.Cone,
      cylinder: Scatter3DSeries.Mesh.Cylinder,
      bevel_bar: Scatter3DSeries.Mesh.BevelBar,
      bevel_cube: Scatter3DSeries.Mesh.BevelCube,
      sphere: Scatter3DSeries.Mesh.Sphere,
      minimal: Scatter3DSeries.Mesh.Minimal,
      arrow: Scatter3DSeries.Mesh.Arrow,
      point: Scatter3DSeries.Mesh.Point
    }
    var mesh = meshes[String(name)]
    return mesh === undefined ? Scatter3DSeries.Mesh.Sphere : mesh
  }

  function colorStyleFor(name) {
    var styles = {
      uniform: GraphsTheme.ColorStyle.Uniform,
      object_gradient: GraphsTheme.ColorStyle.ObjectGradient,
      range_gradient: GraphsTheme.ColorStyle.RangeGradient
    }
    var style = styles[String(name)]
    return style === undefined ? GraphsTheme.ColorStyle.Uniform : style
  }

  function attach() {
    if (root.nativeSeries) return
    var host = root.graphsHost()
    if (!host) {
      renderer.componentError("graph_3d_series_without_graph",
                              "A graph_scatter_3d_series must be declared inside a graph_scatter_3d", {})
      return
    }
    root.ownerGraph = host
    root.nativeSeries = seriesComponent.createObject(host)
    if (root.nativeSeries) host.addSeries(root.nativeSeries)
  }

  Component {
    id: seriesComponent
    Scatter3DSeries {
      name: String(root.renderer.prop("name", ""))
      visible: root.renderer.prop("visible", true) !== false
      itemLabelFormat: String(root.renderer.prop("item_label_format", "@valueLabel"))
      itemLabelVisible: root.renderer.prop("item_label_visible", true) !== false
      mesh: root.meshFor(root.renderer.prop("mesh", "sphere"))
      meshSmooth: root.renderer.prop("mesh_smooth", false) === true
      userDefinedMesh: String(root.renderer.prop("user_defined_mesh", ""))
      colorStyle: root.colorStyleFor(root.renderer.prop("color_style", "uniform"))
      baseColor: root.renderer.prop("base_color", root.renderer.foreground)
      singleHighlightColor: root.renderer.prop("single_highlight_color", root.renderer.foreground)
      multiHighlightColor: root.renderer.prop("multi_highlight_color", root.renderer.foreground)
      itemSize: Number(root.renderer.prop("item_size", 0))
      selectedItem: Number(root.renderer.prop("selected_item", -1))
      onSelectedItemChanged: root.send("select", { index: selectedItem })
    }
  }

  // Data proxy children render through the normal child delegate; they find this
  // series by walking up to the zuiSeriesHost marker above.
  Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }

  Component.onCompleted: root.attach()
  // The graph owns the series after addSeries, so hand it back rather than
  // destroying it from here.
  Component.onDestruction: {
    if (root.ownerGraph && root.nativeSeries) root.ownerGraph.removeSeries(root.nativeSeries)
    root.nativeSeries = null
    root.ownerGraph = null
  }
}
