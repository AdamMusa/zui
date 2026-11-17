import QtQuick
import QtGraphs

// A QtGraphs theme is a standalone object assigned to a graph's theme property,
// so it works for the 2D view and for every 3D graph. The adapter stays an
// invisible item, builds the theme with real bindings and hands it to the graph
// it finds above it. QML completes children before their parent, so an attach
// that finds no graph yet is retried once the current event loop pass has
// finished building the subtree.
Item {
  id: root
  required property var renderer

  property var nativeTheme: null

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

  // QtGraphs enforces scoped enums, so every value is named through its enum.
  function colorScheme(name) {
    var schemes = {
      automatic: GraphsTheme.ColorScheme.Automatic,
      light: GraphsTheme.ColorScheme.Light,
      dark: GraphsTheme.ColorScheme.Dark
    }
    var scheme = schemes[String(name)]
    return scheme === undefined ? GraphsTheme.ColorScheme.Automatic : scheme
  }

  function themePreset(name) {
    var presets = {
      qt_green: GraphsTheme.Theme.QtGreen,
      qt_green_neon: GraphsTheme.Theme.QtGreenNeon,
      mix: GraphsTheme.Theme.MixSeries,
      orange: GraphsTheme.Theme.OrangeSeries,
      yellow: GraphsTheme.Theme.YellowSeries,
      blue: GraphsTheme.Theme.BlueSeries,
      purple: GraphsTheme.Theme.PurpleSeries,
      grey: GraphsTheme.Theme.GreySeries,
      user_defined: GraphsTheme.Theme.UserDefined
    }
    var preset = presets[String(name)]
    return preset === undefined ? GraphsTheme.Theme.QtGreen : preset
  }

  function colorStyle(name) {
    var styles = {
      uniform: GraphsTheme.ColorStyle.Uniform,
      object_gradient: GraphsTheme.ColorStyle.ObjectGradient,
      range_gradient: GraphsTheme.ColorStyle.RangeGradient
    }
    var style = styles[String(name)]
    return style === undefined ? GraphsTheme.ColorStyle.Uniform : style
  }

  function colorList(key) {
    var colors = renderer.prop(key, [])
    if (!Array.isArray(colors)) return []
    return colors.map(function(color) { return String(color) })
  }

  function attach() {
    if (root.nativeTheme) return
    var host = root.graphsHost()
    if (!host) return
    root.nativeTheme = themeComponent.createObject(host)
    if (root.nativeTheme) host.theme = root.nativeTheme
  }

  function attachOrReport() {
    root.attach()
    if (root.nativeTheme) return
    renderer.componentError("graphs_theme_without_graph",
                            "A graphs_theme must be declared inside a graphs_view or a 3D graph", {})
  }

  Component {
    id: themeComponent
    GraphsTheme {
      colorScheme: root.colorScheme(root.renderer.prop("color_scheme", "automatic"))
      theme: root.themePreset(root.renderer.prop("theme", "qt_green"))
      colorStyle: root.colorStyle(root.renderer.prop("color_style", "uniform"))
      backgroundColor: root.renderer.prop("background_color", "transparent")
      backgroundVisible: root.renderer.prop("background_visible", true) !== false
      plotAreaBackgroundColor: root.renderer.prop("plot_area_background_color", "transparent")
      plotAreaBackgroundVisible: root.renderer.prop("plot_area_background_visible", true) !== false
      gridVisible: root.renderer.prop("grid_visible", true) !== false
      labelsVisible: root.renderer.prop("labels_visible", true) !== false
      labelBackgroundColor: root.renderer.prop("label_background_color", "transparent")
      labelTextColor: root.renderer.prop("label_text_color", root.renderer.foreground)
      labelBackgroundVisible: root.renderer.prop("label_background_visible", true) !== false
      labelBorderVisible: root.renderer.prop("label_border_visible", true) !== false
      labelFont.family: String(root.renderer.prop("label_font_family", root.renderer.fontFamily))
      labelFont.pixelSize: Number(root.renderer.prop("label_font_size", 11))
      axisXLabelFont.family: String(root.renderer.prop("axis_x_label_font_family", root.renderer.fontFamily))
      axisXLabelFont.pixelSize: Number(root.renderer.prop("axis_x_label_font_size", 11))
      axisYLabelFont.family: String(root.renderer.prop("axis_y_label_font_family", root.renderer.fontFamily))
      axisYLabelFont.pixelSize: Number(root.renderer.prop("axis_y_label_font_size", 11))
      axisZLabelFont.family: String(root.renderer.prop("axis_z_label_font_family", root.renderer.fontFamily))
      axisZLabelFont.pixelSize: Number(root.renderer.prop("axis_z_label_font_size", 11))
      seriesColors: root.colorList("series_colors")
      borderColors: root.colorList("border_colors")
      borderWidth: Number(root.renderer.prop("border_width", 1))
      singleHighlightColor: root.renderer.prop("single_highlight_color", root.renderer.foreground)
      multiHighlightColor: root.renderer.prop("multi_highlight_color", root.renderer.foreground)
      grid.mainColor: root.renderer.prop("grid_main_color", root.renderer.foreground)
      grid.subColor: root.renderer.prop("grid_sub_color", root.renderer.foreground)
      grid.mainWidth: Number(root.renderer.prop("grid_main_width", 1))
      grid.subWidth: Number(root.renderer.prop("grid_sub_width", 1))
      grid.labelTextColor: root.renderer.prop("grid_label_text_color", root.renderer.foreground)
      axisX.mainColor: root.renderer.prop("axis_x_main_color", root.renderer.foreground)
      axisX.subColor: root.renderer.prop("axis_x_sub_color", root.renderer.foreground)
      axisX.mainWidth: Number(root.renderer.prop("axis_x_main_width", 1))
      axisX.subWidth: Number(root.renderer.prop("axis_x_sub_width", 1))
      axisX.labelTextColor: root.renderer.prop("axis_x_label_text_color", root.renderer.foreground)
      axisY.mainColor: root.renderer.prop("axis_y_main_color", root.renderer.foreground)
      axisY.subColor: root.renderer.prop("axis_y_sub_color", root.renderer.foreground)
      axisY.mainWidth: Number(root.renderer.prop("axis_y_main_width", 1))
      axisY.subWidth: Number(root.renderer.prop("axis_y_sub_width", 1))
      axisY.labelTextColor: root.renderer.prop("axis_y_label_text_color", root.renderer.foreground)
      axisZ.mainColor: root.renderer.prop("axis_z_main_color", root.renderer.foreground)
      axisZ.subColor: root.renderer.prop("axis_z_sub_color", root.renderer.foreground)
      axisZ.mainWidth: Number(root.renderer.prop("axis_z_main_width", 1))
      axisZ.subWidth: Number(root.renderer.prop("axis_z_sub_width", 1))
      axisZ.labelTextColor: root.renderer.prop("axis_z_label_text_color", root.renderer.foreground)
    }
  }

  Component.onCompleted: {
    root.attach()
    if (!root.nativeTheme) Qt.callLater(root.attachOrReport)
  }
}
