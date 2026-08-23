import QtQuick
import "../../Theme"

Item {
  id: canvasRoot
  required property var renderer

  implicitWidth: Number(renderer.prop("width", 320))
  implicitHeight: Number(renderer.prop("height", 200))

  function styleValue(context, value) {
    if (value === null || typeof value !== "object" || Array.isArray(value)) return value
    var kind = String(value.type || "linear")
    var gradient
    if (kind === "radial") {
      gradient = context.createRadialGradient(
        Number(value.x0 || 0), Number(value.y0 || 0), Number(value.r0 || 0),
        Number(value.x1 === undefined ? nativeCanvas.width : value.x1),
        Number(value.y1 === undefined ? nativeCanvas.height : value.y1),
        Number(value.r1 === undefined ? Math.max(nativeCanvas.width, nativeCanvas.height) : value.r1))
    } else {
      gradient = context.createLinearGradient(
        Number(value.x0 || 0), Number(value.y0 || 0),
        Number(value.x1 === undefined ? nativeCanvas.width : value.x1),
        Number(value.y1 || 0))
    }
    var stops = Array.isArray(value.stops) ? value.stops : []
    for (var index = 0; index < stops.length; index++) {
      var stop = stops[index]
      if (Array.isArray(stop)) gradient.addColorStop(Number(stop[0]), String(stop[1]))
      else if (stop && typeof stop === "object") gradient.addColorStop(Number(stop.position), String(stop.color))
    }
    return gradient
  }

  function applyStyle(context, command) {
    if (command.fill_style !== undefined) context.fillStyle = styleValue(context, command.fill_style)
    if (command.stroke_style !== undefined) context.strokeStyle = styleValue(context, command.stroke_style)
    if (command.line_width !== undefined) context.lineWidth = Number(command.line_width)
    if (command.line_cap !== undefined) context.lineCap = String(command.line_cap)
    if (command.line_join !== undefined) context.lineJoin = String(command.line_join)
    if (command.miter_limit !== undefined) context.miterLimit = Number(command.miter_limit)
    if (command.alpha !== undefined) context.globalAlpha = Number(command.alpha)
    if (command.composite !== undefined) context.globalCompositeOperation = String(command.composite)
    if (command.font !== undefined) context.font = String(command.font)
    if (command.text_align !== undefined) context.textAlign = String(command.text_align)
    if (command.text_baseline !== undefined) context.textBaseline = String(command.text_baseline)
    if (command.shadow_color !== undefined) context.shadowColor = String(command.shadow_color)
    if (command.shadow_blur !== undefined) context.shadowBlur = Number(command.shadow_blur)
    if (command.shadow_offset_x !== undefined) context.shadowOffsetX = Number(command.shadow_offset_x)
    if (command.shadow_offset_y !== undefined) context.shadowOffsetY = Number(command.shadow_offset_y)
  }

  function roundedRect(context, command) {
    var x = Number(command.x || 0)
    var y = Number(command.y || 0)
    var width = Number(command.width || 0)
    var height = Number(command.height || 0)
    var radius = Math.max(0, Math.min(Number(command.radius || 0), Math.min(Math.abs(width), Math.abs(height)) / 2))
    context.moveTo(x + radius, y)
    context.lineTo(x + width - radius, y)
    context.quadraticCurveTo(x + width, y, x + width, y + radius)
    context.lineTo(x + width, y + height - radius)
    context.quadraticCurveTo(x + width, y + height, x + width - radius, y + height)
    context.lineTo(x + radius, y + height)
    context.quadraticCurveTo(x, y + height, x, y + height - radius)
    context.lineTo(x, y + radius)
    context.quadraticCurveTo(x, y, x + radius, y)
  }

  function draw(context, command) {
    if (!command || typeof command !== "object") return
    applyStyle(context, command)
    var operation = String(command.op || command.type || "")
    if (operation === "save") context.save()
    else if (operation === "restore") context.restore()
    else if (operation === "begin_path") context.beginPath()
    else if (operation === "close_path") context.closePath()
    else if (operation === "move_to") context.moveTo(Number(command.x || 0), Number(command.y || 0))
    else if (operation === "line_to") context.lineTo(Number(command.x || 0), Number(command.y || 0))
    else if (operation === "bezier_curve_to") context.bezierCurveTo(Number(command.cp1x || 0), Number(command.cp1y || 0), Number(command.cp2x || 0), Number(command.cp2y || 0), Number(command.x || 0), Number(command.y || 0))
    else if (operation === "quadratic_curve_to") context.quadraticCurveTo(Number(command.cpx || 0), Number(command.cpy || 0), Number(command.x || 0), Number(command.y || 0))
    else if (operation === "arc") context.arc(Number(command.x || 0), Number(command.y || 0), Number(command.radius || 0), Number(command.start_angle || 0), Number(command.end_angle === undefined ? Math.PI * 2 : command.end_angle), command.counterclockwise === true)
    else if (operation === "arc_to") context.arcTo(Number(command.x1 || 0), Number(command.y1 || 0), Number(command.x2 || 0), Number(command.y2 || 0), Number(command.radius || 0))
    else if (operation === "rect") context.rect(Number(command.x || 0), Number(command.y || 0), Number(command.width || 0), Number(command.height || 0))
    else if (operation === "rounded_rect") roundedRect(context, command)
    else if (operation === "fill") context.fill(String(command.fill_rule || "nonzero"))
    else if (operation === "stroke") context.stroke()
    else if (operation === "clip") context.clip()
    else if (operation === "clear_rect") context.clearRect(Number(command.x || 0), Number(command.y || 0), Number(command.width === undefined ? nativeCanvas.width : command.width), Number(command.height === undefined ? nativeCanvas.height : command.height))
    else if (operation === "fill_rect") context.fillRect(Number(command.x || 0), Number(command.y || 0), Number(command.width || 0), Number(command.height || 0))
    else if (operation === "stroke_rect") context.strokeRect(Number(command.x || 0), Number(command.y || 0), Number(command.width || 0), Number(command.height || 0))
    else if (operation === "fill_text") context.fillText(String(command.text || ""), Number(command.x || 0), Number(command.y || 0), command.max_width === undefined ? 1e9 : Number(command.max_width))
    else if (operation === "stroke_text") context.strokeText(String(command.text || ""), Number(command.x || 0), Number(command.y || 0), command.max_width === undefined ? 1e9 : Number(command.max_width))
    else if (operation === "translate") context.translate(Number(command.x || 0), Number(command.y || 0))
    else if (operation === "rotate") context.rotate(Number(command.angle || 0))
    else if (operation === "scale") context.scale(Number(command.x === undefined ? 1 : command.x), Number(command.y === undefined ? 1 : command.y))
    else if (operation === "transform") context.transform(Number(command.a === undefined ? 1 : command.a), Number(command.b || 0), Number(command.c || 0), Number(command.d === undefined ? 1 : command.d), Number(command.e || 0), Number(command.f || 0))
    else if (operation === "set_transform") context.setTransform(Number(command.a === undefined ? 1 : command.a), Number(command.b || 0), Number(command.c || 0), Number(command.d === undefined ? 1 : command.d), Number(command.e || 0), Number(command.f || 0))
  }

  Rectangle {
    anchors.fill: parent
    color: renderer.prop("background", "transparent")
  }

  Canvas {
    id: nativeCanvas
    anchors.fill: parent
    antialiasing: renderer.prop("antialiasing", true) !== false
    smooth: renderer.prop("smooth", true) !== false
    canvasSize: Qt.size(Number(renderer.prop("canvas_width", width)), Number(renderer.prop("canvas_height", height)))
    tileSize: Qt.size(Number(renderer.prop("tile_width", 0)), Number(renderer.prop("tile_height", 0)))
    renderTarget: String(renderer.prop("render_target", "image")) === "framebuffer" ? Canvas.FramebufferObject : Canvas.Image
    renderStrategy: {
      var strategy = String(renderer.prop("render_strategy", "immediate"))
      if (strategy === "threaded") return Canvas.Threaded
      if (strategy === "cooperative") return Canvas.Cooperative
      return Canvas.Immediate
    }
    onPaint: {
      var context = getContext("2d")
      try {
        context.reset()
        context.clearRect(0, 0, width, height)
        var commands = renderer.prop("commands", [])
        if (Array.isArray(commands)) {
          for (var index = 0; index < commands.length; index++) canvasRoot.draw(context, commands[index])
        }
        if (renderer.subscribed("paint")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "paint", { commands: Array.isArray(commands) ? commands.length : 0 })
      } catch (error) {
        if (renderer.subscribed("error")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "error", { message: String(error) })
      }
    }
  }

  Connections {
    target: renderer
    function onNodeChanged() { nativeCanvas.requestPaint() }
  }

  Timer {
    interval: Math.max(1, Math.round(1000 / Math.max(1, Number(renderer.prop("fps", 60)))))
    repeat: true
    running: renderer.prop("continuous", false) === true
    onTriggered: nativeCanvas.requestPaint()
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: renderer.subscribed("hover")
    function payload(mouse) { return { x: mouse.x, y: mouse.y, button: mouse.button } }
    onClicked: function(mouse) { if (renderer.subscribed("click")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", payload(mouse)) }
    onDoubleClicked: function(mouse) { if (renderer.subscribed("double_click")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "double_click", payload(mouse)) }
    onPressed: function(mouse) { if (renderer.subscribed("press")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "press", payload(mouse)) }
    onReleased: function(mouse) { if (renderer.subscribed("release")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "release", payload(mouse)) }
    onPositionChanged: function(mouse) { if (renderer.subscribed("hover")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", payload(mouse)) }
  }
}
