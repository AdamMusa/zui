import QtQuick
import QtCharts

// A QtCharts axis belongs to a series, which hands it to the chart. The adapter
// stays an invisible item in the zui tree, builds the native axis with real
// bindings and assigns it to the axis slot named by its position property. QML
// completes children before their parent, so an attach that finds no series yet
// is retried once the current event loop pass has finished building the subtree.
Item {
  id: root
  required property var renderer

  readonly property bool zuiAxisHost: true
  property var nativeAxis: null

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

  function send(name, payload) {
    if (renderer.subscribed(name)) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }

  function axisProperty() {
    var positions = {
      x: "axisX", y: "axisY", x_top: "axisXTop", y_right: "axisYRight",
      angular: "axisAngular", radial: "axisRadial"
    }
    var property = positions[String(renderer.prop("position", "x"))]
    return property === undefined ? "axisX" : property
  }

  function tickType(name) {
    return String(name) === "fixed" ? ValueAxis.TicksFixed : ValueAxis.TicksDynamic
  }

  function attach() {
    if (root.nativeAxis) return
    var host = root.seriesHost()
    if (!host || !host.nativeSeries) return

    var property = root.axisProperty()
    // Angular and radial slots only exist on polar XY series, and a pie series
    // has no axes at all. Report that instead of throwing on assignment.
    if (host.nativeSeries[property] === undefined) {
      renderer.componentError("chart_axis_position_unsupported",
                              "This chart series has no " + property + " slot", { position: property })
      return
    }
    root.nativeAxis = axisComponent.createObject(host.nativeSeries)
    if (root.nativeAxis) host.nativeSeries[property] = root.nativeAxis
  }

  function attachOrReport() {
    root.attach()
    if (root.nativeAxis) return
    renderer.componentError("chart_axis_without_series",
                            "A chart axis must be declared inside a chart series", {})
  }

  Component {
    id: axisComponent
    ValueAxis {
      visible: root.renderer.prop("visible", true) !== false
      lineVisible: root.renderer.prop("line_visible", true) !== false
      color: root.renderer.prop("color", root.renderer.foreground)
      labelsVisible: root.renderer.prop("labels_visible", true) !== false
      labelsAngle: Number(root.renderer.prop("labels_angle", 0))
      labelsColor: root.renderer.prop("labels_color", root.renderer.foreground)
      labelsFont.family: String(root.renderer.prop("labels_font_family", root.renderer.fontFamily))
      labelsFont.pixelSize: Number(root.renderer.prop("labels_font_size", 11))
      truncateLabels: root.renderer.prop("truncate_labels", true) !== false
      gridVisible: root.renderer.prop("grid_visible", true) !== false
      minorGridVisible: root.renderer.prop("minor_grid_visible", false) === true
      gridLineColor: root.renderer.prop("grid_line_color", root.renderer.foreground)
      minorGridLineColor: root.renderer.prop("minor_grid_line_color", root.renderer.foreground)
      shadesVisible: root.renderer.prop("shades_visible", false) === true
      shadesColor: root.renderer.prop("shades_color", "transparent")
      shadesBorderColor: root.renderer.prop("shades_border_color", "transparent")
      titleText: String(root.renderer.prop("title", ""))
      titleVisible: root.renderer.prop("title_visible", true) !== false
      titleFont.family: String(root.renderer.prop("title_font_family", root.renderer.fontFamily))
      titleFont.pixelSize: Number(root.renderer.prop("title_font_size", 12))
      reverse: root.renderer.prop("reverse", false) === true
      min: Number(root.renderer.prop("minimum", 0))
      max: Number(root.renderer.prop("maximum", 10))
      tickCount: Number(root.renderer.prop("tick_count", 5))
      minorTickCount: Number(root.renderer.prop("minor_tick_count", 0))
      tickAnchor: Number(root.renderer.prop("tick_anchor", 0))
      tickInterval: Number(root.renderer.prop("tick_interval", 0))
      tickType: root.tickType(root.renderer.prop("tick_type", "dynamic"))
      labelFormat: String(root.renderer.prop("label_format", ""))
      onRangeChanged: root.send("range_change", { minimum: min, maximum: max })
    }
  }

  Component.onCompleted: {
    root.attach()
    if (!root.nativeAxis) Qt.callLater(root.attachOrReport)
  }
}
