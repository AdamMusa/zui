import QtQuick
import QtGraphs

// In QtGraphs an axis belongs to the graph, not to a series, so the adapter is
// declared inside the graph and fills the slot its position property names. QML
// completes children before their parent, so an attach that finds no graph yet
// is retried once the current event loop pass has finished building the subtree.
Item {
  id: root
  required property var renderer

  readonly property bool zuiAxisHost: true
  property var nativeAxis: null

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

  function axisProperty() {
    var positions = { x: "axisX", y: "axisY", z: "axisZ" }
    var property = positions[String(renderer.prop("position", "x"))]
    return property === undefined ? "axisX" : property
  }

  function axisCategories() {
    var categories = renderer.prop("categories", [])
    if (!Array.isArray(categories)) return []
    return categories.map(function(category) { return String(category) })
  }

  function attach() {
    if (root.nativeAxis) return
    var host = root.graphsHost()
    if (!host) return

    var property = root.axisProperty()
    // A 2D graph has no z axis, and Bars3D names its axes rowAxis, columnAxis
    // and valueAxis instead. Report that rather than throwing on assignment.
    if (host[property] === undefined) {
      renderer.componentError("graph_axis_position_unsupported",
                              "This graph has no " + property + " slot", { position: property })
      return
    }
    root.nativeAxis = axisComponent.createObject(host)
    if (root.nativeAxis) host[property] = root.nativeAxis
  }

  function attachOrReport() {
    root.attach()
    if (root.nativeAxis) return
    renderer.componentError("graph_axis_without_graph",
                            "A graph axis must be declared inside a graphs_view or a 3D graph", {})
  }

  Component {
    id: axisComponent
    BarCategoryAxis {
      visible: root.renderer.prop("visible", true) !== false
      lineVisible: root.renderer.prop("line_visible", true) !== false
      labelsVisible: root.renderer.prop("labels_visible", true) !== false
      labelsAngle: Number(root.renderer.prop("labels_angle", 0))
      gridVisible: root.renderer.prop("grid_visible", true) !== false
      subGridVisible: root.renderer.prop("sub_grid_visible", false) === true
      titleText: String(root.renderer.prop("title", ""))
      titleColor: root.renderer.prop("title_color", root.renderer.foreground)
      titleVisible: root.renderer.prop("title_visible", true) !== false
      titleFont.family: String(root.renderer.prop("title_font_family", root.renderer.fontFamily))
      titleFont.pixelSize: Number(root.renderer.prop("title_font_size", 12))
      categories: root.axisCategories()
      min: String(root.renderer.prop("minimum", ""))
      max: String(root.renderer.prop("maximum", ""))
    }
  }

  Component.onCompleted: {
    root.attach()
    if (!root.nativeAxis) Qt.callLater(root.attachOrReport)
  }
}
