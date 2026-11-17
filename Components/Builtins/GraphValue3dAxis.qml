import QtQuick
import QtGraphs

// A QtGraphs 3D axis belongs to the graph. Scatter3D and Surface3D name their
// slots axisX/axisY/axisZ while Bars3D names them rowAxis/columnAxis/valueAxis,
// so position accepts either spelling. QML completes children before their
// parent, so an attach that finds no graph yet is retried once the current event
// loop pass has finished building the subtree.
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
    var positions = {
      x: "axisX", y: "axisY", z: "axisZ",
      row: "rowAxis", column: "columnAxis", value: "valueAxis"
    }
    var property = positions[String(renderer.prop("position", "y"))]
    return property === undefined ? "axisY" : property
  }

  function labelList(key) {
    var labels = renderer.prop(key, [])
    if (!Array.isArray(labels)) return []
    return labels.map(function(label) { return String(label) })
  }

  function attach() {
    if (root.nativeAxis) return
    var host = root.graphsHost()
    if (!host) return

    var property = root.axisProperty()
    // Bars3D and Scatter3D name their slots differently, so a position meant
    // for the other graph is reported rather than thrown on assignment.
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
                            "A graph_value_3d_axis must be declared inside a 3D graph", {})
  }

  Component {
    id: axisComponent
    Value3DAxis {
      title: String(root.renderer.prop("title", ""))
      titleVisible: root.renderer.prop("title_visible", false) === true
      titleFixed: root.renderer.prop("title_fixed", true) !== false
      titleOffset: Number(root.renderer.prop("title_offset", 0))
      labels: root.labelList("labels")
      labelsVisible: root.renderer.prop("labels_visible", true) !== false
      labelAutoAngle: Number(root.renderer.prop("label_auto_angle", 0))
      min: Number(root.renderer.prop("minimum", 0))
      max: Number(root.renderer.prop("maximum", 10))
      autoAdjustRange: root.renderer.prop("auto_adjust_range", false) === true
      segmentCount: Number(root.renderer.prop("segment_count", 5))
      subSegmentCount: Number(root.renderer.prop("sub_segment_count", 1))
      labelFormat: String(root.renderer.prop("label_format", "%.2f"))
      reversed: root.renderer.prop("reversed", false) === true
      onRangeChanged: root.send("range_change", { minimum: min, maximum: max })
    }
  }

  function send(name, payload) {
    if (renderer.subscribed(name)) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }

  // Formatter children render through the normal child delegate; they find this
  // axis by walking up to the zuiAxisHost marker above.
  Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }

  Component.onCompleted: {
    root.attach()
    if (!root.nativeAxis) Qt.callLater(root.attachOrReport)
  }
}
