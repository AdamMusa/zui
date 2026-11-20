import QtQuick

// Builds real QtQuick path elements from declarative segment descriptions so
// Ruby can compose a Path out of the Qt element types instead of an SVG string.
QtObject {
  id: factory

  readonly property Component lineFactory: Component { PathLine {} }
  readonly property Component moveFactory: Component { PathMove {} }
  readonly property Component quadFactory: Component { PathQuad {} }
  readonly property Component cubicFactory: Component { PathCubic {} }
  readonly property Component curveFactory: Component { PathCurve {} }
  readonly property Component arcFactory: Component { PathArc {} }
  readonly property Component angleArcFactory: Component { PathAngleArc {} }
  readonly property Component svgFactory: Component { PathSvg {} }
  readonly property Component polylineFactory: Component { PathPolyline {} }
  readonly property Component multilineFactory: Component { PathMultiline {} }
  readonly property Component rectangleFactory: Component { PathRectangle {} }
  readonly property Component textFactory: Component { PathText {} }
  readonly property Component attributeFactory: Component { PathAttribute {} }
  readonly property Component percentFactory: Component { PathPercent {} }

  readonly property var kinds: ["line", "move", "quad", "cubic", "curve", "arc", "angle_arc",
    "svg", "polyline", "multiline", "rectangle", "text", "attribute", "percent"]

  function componentFor(kind) {
    if (kind === "line") return lineFactory
    if (kind === "move") return moveFactory
    if (kind === "quad") return quadFactory
    if (kind === "cubic") return cubicFactory
    if (kind === "curve") return curveFactory
    if (kind === "arc") return arcFactory
    if (kind === "angle_arc") return angleArcFactory
    if (kind === "svg") return svgFactory
    if (kind === "polyline") return polylineFactory
    if (kind === "multiline") return multilineFactory
    if (kind === "rectangle") return rectangleFactory
    if (kind === "text") return textFactory
    if (kind === "attribute") return attributeFactory
    if (kind === "percent") return percentFactory
    return null
  }

  function number(specification, key, fallback) {
    return specification[key] === undefined ? fallback : Number(specification[key])
  }

  function points(requested) {
    if (!Array.isArray(requested)) return []
    var resolved = []
    for (var index = 0; index < requested.length; index++) {
      var entry = requested[index]
      if (Array.isArray(entry)) resolved.push(Qt.point(Number(entry[0]), Number(entry[1])))
      else if (entry && typeof entry === "object") resolved.push(Qt.point(Number(entry.x), Number(entry.y)))
    }
    return resolved
  }

  function curveProperties(specification) {
    var resolved = {}
    if (specification.x !== undefined) resolved.x = Number(specification.x)
    if (specification.y !== undefined) resolved.y = Number(specification.y)
    if (specification.relative_x !== undefined) resolved.relativeX = Number(specification.relative_x)
    if (specification.relative_y !== undefined) resolved.relativeY = Number(specification.relative_y)
    return resolved
  }

  function assign(target, source) {
    for (var key in source) target[key] = source[key]
    return target
  }

  function properties(kind, specification) {
    if (kind === "line" || kind === "move" || kind === "curve") return curveProperties(specification)
    if (kind === "quad") {
      var quad = curveProperties(specification)
      if (specification.control_x !== undefined) quad.controlX = Number(specification.control_x)
      if (specification.control_y !== undefined) quad.controlY = Number(specification.control_y)
      if (specification.relative_control_x !== undefined) quad.relativeControlX = Number(specification.relative_control_x)
      if (specification.relative_control_y !== undefined) quad.relativeControlY = Number(specification.relative_control_y)
      return quad
    }
    if (kind === "cubic") {
      var cubic = curveProperties(specification)
      if (specification.control1_x !== undefined) cubic.control1X = Number(specification.control1_x)
      if (specification.control1_y !== undefined) cubic.control1Y = Number(specification.control1_y)
      if (specification.control2_x !== undefined) cubic.control2X = Number(specification.control2_x)
      if (specification.control2_y !== undefined) cubic.control2Y = Number(specification.control2_y)
      if (specification.relative_control1_x !== undefined) cubic.relativeControl1X = Number(specification.relative_control1_x)
      if (specification.relative_control1_y !== undefined) cubic.relativeControl1Y = Number(specification.relative_control1_y)
      if (specification.relative_control2_x !== undefined) cubic.relativeControl2X = Number(specification.relative_control2_x)
      if (specification.relative_control2_y !== undefined) cubic.relativeControl2Y = Number(specification.relative_control2_y)
      return cubic
    }
    if (kind === "arc") {
      var arc = curveProperties(specification)
      arc.radiusX = number(specification, "radius_x", 0)
      arc.radiusY = number(specification, "radius_y", 0)
      arc.useLargeArc = specification.use_large_arc === true
      arc.direction = String(specification.direction) === "counterclockwise"
        ? PathArc.Counterclockwise : PathArc.Clockwise
      arc.xAxisRotation = number(specification, "x_axis_rotation", 0)
      return arc
    }
    if (kind === "angle_arc") {
      return {
        centerX: number(specification, "center_x", 0), centerY: number(specification, "center_y", 0),
        radiusX: number(specification, "radius_x", 0), radiusY: number(specification, "radius_y", 0),
        startAngle: number(specification, "start_angle", 0),
        sweepAngle: number(specification, "sweep_angle", 0),
        moveToStart: specification.move_to_start !== false
      }
    }
    if (kind === "svg") return { path: String(specification.path === undefined ? "" : specification.path) }
    if (kind === "polyline") {
      return {
        start: Qt.point(number(specification, "start_x", 0), number(specification, "start_y", 0)),
        path: points(specification.points)
      }
    }
    if (kind === "multiline") {
      var lines = []
      var requested = Array.isArray(specification.paths) ? specification.paths : []
      for (var index = 0; index < requested.length; index++) lines.push(points(requested[index]))
      return {
        start: Qt.point(number(specification, "start_x", 0), number(specification, "start_y", 0)),
        paths: lines
      }
    }
    if (kind === "rectangle") {
      var rectangle = curveProperties(specification)
      rectangle.width = number(specification, "width", 0)
      rectangle.height = number(specification, "height", 0)
      rectangle.strokeAdjustment = number(specification, "stroke_adjustment", 0)
      rectangle.radius = number(specification, "radius", 0)
      if (specification.top_left_radius !== undefined) rectangle.topLeftRadius = Number(specification.top_left_radius)
      if (specification.top_right_radius !== undefined) rectangle.topRightRadius = Number(specification.top_right_radius)
      if (specification.bottom_left_radius !== undefined) rectangle.bottomLeftRadius = Number(specification.bottom_left_radius)
      if (specification.bottom_right_radius !== undefined) rectangle.bottomRightRadius = Number(specification.bottom_right_radius)
      return rectangle
    }
    if (kind === "text") {
      return {
        x: number(specification, "x", 0), y: number(specification, "y", 0),
        text: String(specification.text === undefined ? "" : specification.text)
      }
    }
    if (kind === "attribute") {
      return {
        name: String(specification.name === undefined ? "" : specification.name),
        value: number(specification, "value", 0)
      }
    }
    if (kind === "percent") return { value: number(specification, "value", 0) }
    return {}
  }

  function create(owner, specification) {
    if (!specification || typeof specification !== "object") return null
    var kind = String(specification.type)
    var component = componentFor(kind)
    if (!component) return null
    var element = component.createObject(owner, properties(kind, specification))
    if (element && kind === "text") {
      element.font = Qt.font({
        family: String(specification.font_family === undefined ? Qt.application.font.family : specification.font_family),
        pixelSize: number(specification, "font_size", 24),
        bold: specification.bold === true,
        italic: specification.italic === true
      })
    }
    return element
  }

  // Returns { elements: [...], rejected: [...] } so a caller can report unknown
  // segment types instead of quietly dropping them.
  function build(owner, requested) {
    var elements = []
    var rejected = []
    if (!Array.isArray(requested)) return { elements: elements, rejected: rejected }
    for (var index = 0; index < requested.length; index++) {
      var element = create(owner, requested[index])
      if (element) elements.push(element)
      else rejected.push(requested[index] && requested[index].type !== undefined
        ? String(requested[index].type) : "(missing type)")
    }
    return { elements: elements, rejected: rejected }
  }
}
