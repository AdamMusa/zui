import QtQuick
import QtGraphs

// A QtGraphs 3D series is handed to the graph through addSeries(), so the
// adapter stays an invisible item, builds the native series with real bindings
// and gives it to the Surface3D above it.
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
      user_defined: Surface3DSeries.Mesh.UserDefined,
      bar: Surface3DSeries.Mesh.Bar,
      cube: Surface3DSeries.Mesh.Cube,
      pyramid: Surface3DSeries.Mesh.Pyramid,
      cone: Surface3DSeries.Mesh.Cone,
      cylinder: Surface3DSeries.Mesh.Cylinder,
      bevel_bar: Surface3DSeries.Mesh.BevelBar,
      bevel_cube: Surface3DSeries.Mesh.BevelCube,
      sphere: Surface3DSeries.Mesh.Sphere,
      minimal: Surface3DSeries.Mesh.Minimal,
      arrow: Surface3DSeries.Mesh.Arrow,
      point: Surface3DSeries.Mesh.Point
    }
    var mesh = meshes[String(name)]
    return mesh === undefined ? Surface3DSeries.Mesh.Sphere : mesh
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

  // DrawFlag is an unscoped flag enum while Shading is scoped, so the two are
  // named differently. qmllint is what keeps that honest.
  function drawModeFor(name) {
    var modes = {
      wireframe: Surface3DSeries.DrawWireframe,
      surface: Surface3DSeries.DrawSurface,
      surface_and_wireframe: Surface3DSeries.DrawSurfaceAndWireframe
    }
    var mode = modes[String(name)]
    return mode === undefined ? Surface3DSeries.DrawSurfaceAndWireframe : mode
  }

  function shadingFor(name) {
    return String(name) === "flat" ? Surface3DSeries.Shading.Flat : Surface3DSeries.Shading.Smooth
  }

  function attach() {
    if (root.nativeSeries) return
    var host = root.graphsHost()
    if (!host) {
      renderer.componentError("graph_3d_series_without_graph",
                              "A graph_surface_3d_series must be declared inside a graph_surface_3d", {})
      return
    }
    root.ownerGraph = host
    root.nativeSeries = seriesComponent.createObject(host)
    if (root.nativeSeries) host.addSeries(root.nativeSeries)
  }

  Component {
    id: seriesComponent
    Surface3DSeries {
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
      drawMode: root.drawModeFor(root.renderer.prop("draw_mode", "surface_and_wireframe"))
      shading: root.shadingFor(root.renderer.prop("shading", "smooth"))
      textureFile: String(root.renderer.prop("texture_file", ""))
      wireframeColor: root.renderer.prop("wireframe_color", root.renderer.foreground)
      selectedPoint: Qt.point(Number(root.renderer.prop("selected_row", -1)),
                              Number(root.renderer.prop("selected_column", -1)))
      onSelectedPointChanged: root.send("select", { row: selectedPoint.x, column: selectedPoint.y })
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
