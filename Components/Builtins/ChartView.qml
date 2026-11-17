import QtQuick
import QtCharts

ChartView {
  id: root
  required property var renderer

  // Chart children locate their host by walking up the visual parent chain.
  readonly property bool zuiChartHost: true
  property real appliedZoom: 1

  function send(name, payload) {
    if (renderer.subscribed(name)) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }

  function chartTheme(name) {
    var themes = {
      light: ChartView.ChartThemeLight,
      blue_cerulean: ChartView.ChartThemeBlueCerulean,
      dark: ChartView.ChartThemeDark,
      brown_sand: ChartView.ChartThemeBrownSand,
      blue_ncs: ChartView.ChartThemeBlueNcs,
      high_contrast: ChartView.ChartThemeHighContrast,
      blue_icy: ChartView.ChartThemeBlueIcy,
      qt: ChartView.ChartThemeQt
    }
    var theme = themes[String(name)]
    return theme === undefined ? ChartView.ChartThemeLight : theme
  }

  function chartAnimation(name) {
    var options = {
      none: ChartView.NoAnimation,
      grid: ChartView.GridAxisAnimations,
      series: ChartView.SeriesAnimations,
      all: ChartView.AllAnimations
    }
    var option = options[String(name)]
    return option === undefined ? ChartView.AllAnimations : option
  }

  function legendAlignment(name) {
    var alignments = { top: Qt.AlignTop, bottom: Qt.AlignBottom, left: Qt.AlignLeft, right: Qt.AlignRight }
    var alignment = alignments[String(name)]
    return alignment === undefined ? Qt.AlignBottom : alignment
  }

  function legendMarkerShape(name) {
    var shapes = {
      "default": Legend.MarkerShapeDefault,
      rectangle: Legend.MarkerShapeRectangle,
      circle: Legend.MarkerShapeCircle,
      from_series: Legend.MarkerShapeFromSeries,
      rotated_rectangle: Legend.MarkerShapeRotatedRectangle,
      triangle: Legend.MarkerShapeTriangle,
      star: Legend.MarkerShapeStar,
      pentagon: Legend.MarkerShapePentagon
    }
    var shape = shapes[String(name)]
    return shape === undefined ? Legend.MarkerShapeDefault : shape
  }

  // zoom() multiplies the current view, so a declarative factor is applied from
  // a reset view. Only a changed request re-zooms, otherwise every unrelated
  // property revision would stack another zoom step onto the plot area.
  function applyZoom() {
    var factor = Number(renderer.prop("zoom", 1))
    if (!isFinite(factor) || factor <= 0) factor = 1
    if (factor === root.appliedZoom) return
    root.appliedZoom = factor
    root.zoomReset()
    if (factor !== 1) root.zoom(factor)
  }

  implicitWidth: Number(renderer.prop("width", 480))
  implicitHeight: Number(renderer.prop("height", 320))
  visible: renderer.prop("visible", true) !== false
  antialiasing: renderer.prop("antialiasing", true) !== false
  theme: root.chartTheme(renderer.prop("theme", "light"))
  animationOptions: root.chartAnimation(renderer.prop("animation", "all"))
  animationDuration: Number(renderer.prop("animation_duration", 1000))
  title: String(renderer.prop("title", ""))
  titleColor: renderer.prop("title_color", renderer.foreground)
  titleFont.family: String(renderer.prop("title_font_family", renderer.fontFamily))
  titleFont.pixelSize: Number(renderer.prop("title_font_size", 16))
  backgroundColor: renderer.prop("background_color", "transparent")
  backgroundRoundness: Number(renderer.prop("background_roundness", 0))
  dropShadowEnabled: renderer.prop("drop_shadow", false) === true
  plotAreaColor: renderer.prop("plot_area_color", "transparent")
  localizeNumbers: renderer.prop("localize_numbers", false) === true
  locale: Qt.locale(String(renderer.prop("locale", Qt.locale().name)))
  margins.top: Number(renderer.prop("margin_top", 20))
  margins.bottom: Number(renderer.prop("margin_bottom", 20))
  margins.left: Number(renderer.prop("margin_left", 20))
  margins.right: Number(renderer.prop("margin_right", 20))
  legend.visible: renderer.prop("legend_visible", true) !== false
  legend.alignment: root.legendAlignment(renderer.prop("legend_alignment", "bottom"))
  legend.backgroundVisible: renderer.prop("legend_background_visible", false) === true
  legend.color: renderer.prop("legend_color", "transparent")
  legend.borderColor: renderer.prop("legend_border_color", "transparent")
  legend.labelColor: renderer.prop("legend_label_color", renderer.foreground)
  legend.font.family: String(renderer.prop("legend_font_family", renderer.fontFamily))
  legend.font.pixelSize: Number(renderer.prop("legend_font_size", 12))
  legend.markerShape: root.legendMarkerShape(renderer.prop("legend_marker_shape", "default"))
  legend.reverseMarkers: renderer.prop("legend_reverse_markers", false) === true
  legend.showToolTips: renderer.prop("legend_show_tooltips", false) === true

  Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }

  onSeriesAdded: function(series) { root.send("series_added", { name: series ? String(series.name) : "" }) }
  onSeriesRemoved: function(series) { root.send("series_removed", { name: series ? String(series.name) : "" }) }
  onPlotAreaChanged: root.send("plot_area_change", {
    x: root.plotArea.x, y: root.plotArea.y, width: root.plotArea.width, height: root.plotArea.height
  })
  Component.onCompleted: root.applyZoom()
  Connections { target: renderer; function onNodeChanged() { root.applyZoom() } }
}
