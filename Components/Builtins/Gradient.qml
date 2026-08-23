import QtQuick
import QtQuick.Shapes

Item {
  id: gradientRoot
  required property var renderer
  property var createdStops: []
  implicitWidth: Number(renderer.prop("width", 200))
  implicitHeight: Number(renderer.prop("height", 120))

  function stopPosition(index, count) {
    var stops = renderer.prop("stops", [])
    return Array.isArray(stops) && index < stops.length ? Number(stops[index]) : (count <= 1 ? 0 : index / (count - 1))
  }

  function rebuildStops() {
    for (var oldIndex = 0; oldIndex < createdStops.length; oldIndex++) createdStops[oldIndex].destroy()
    var colors = renderer.prop("colors", [])
    var replacements = []
    if (Array.isArray(colors)) {
      for (var index = 0; index < colors.length; index++) {
        replacements.push(stopFactory.createObject(gradientRoot, {
          position: stopPosition(index, colors.length), color: String(colors[index])
        }))
      }
    }
    createdStops = replacements
  }

  Component { id: stopFactory; GradientStop {} }
  Connections { target: renderer; function onNodeChanged() { gradientRoot.rebuildStops() } }
  Component.onCompleted: rebuildStops()

  Shape {
    anchors.fill: parent
    visible: String(renderer.prop("type", "linear")) === "linear"
    antialiasing: renderer.prop("antialiasing", true) !== false
    ShapePath {
      strokeColor: renderer.prop("stroke", "transparent")
      strokeWidth: Number(renderer.prop("stroke_width", 0))
      fillGradient: LinearGradient {
        id: linearGradient
        x1: Number(renderer.prop("start_x", 0)); y1: Number(renderer.prop("start_y", 0))
        x2: Number(renderer.prop("end_x", gradientRoot.width)); y2: Number(renderer.prop("end_y", 0))
        stops: String(renderer.prop("type", "linear")) === "linear" ? gradientRoot.createdStops : []
      }
      PathRectangle { width: gradientRoot.width; height: gradientRoot.height; radius: Number(renderer.prop("radius", 0)) }
    }
  }

  Shape {
    anchors.fill: parent
    visible: String(renderer.prop("type", "linear")) === "radial"
    antialiasing: renderer.prop("antialiasing", true) !== false
    ShapePath {
      strokeColor: renderer.prop("stroke", "transparent")
      strokeWidth: Number(renderer.prop("stroke_width", 0))
      fillGradient: RadialGradient {
        id: radialGradient
        centerX: Number(renderer.prop("center_x", gradientRoot.width / 2)); centerY: Number(renderer.prop("center_y", gradientRoot.height / 2))
        centerRadius: Number(renderer.prop("center_radius", Math.max(gradientRoot.width, gradientRoot.height) / 2))
        focalX: Number(renderer.prop("focal_x", centerX)); focalY: Number(renderer.prop("focal_y", centerY))
        focalRadius: Number(renderer.prop("focal_radius", 0))
        stops: String(renderer.prop("type", "linear")) === "radial" ? gradientRoot.createdStops : []
      }
      PathRectangle { width: gradientRoot.width; height: gradientRoot.height; radius: Number(renderer.prop("radius", 0)) }
    }
  }

  Shape {
    anchors.fill: parent
    visible: String(renderer.prop("type", "linear")) === "conical"
    antialiasing: renderer.prop("antialiasing", true) !== false
    ShapePath {
      strokeColor: renderer.prop("stroke", "transparent")
      strokeWidth: Number(renderer.prop("stroke_width", 0))
      fillGradient: ConicalGradient {
        id: conicalGradient
        centerX: Number(renderer.prop("center_x", gradientRoot.width / 2)); centerY: Number(renderer.prop("center_y", gradientRoot.height / 2))
        angle: Number(renderer.prop("angle", 0))
        stops: String(renderer.prop("type", "linear")) === "conical" ? gradientRoot.createdStops : []
      }
      PathRectangle { width: gradientRoot.width; height: gradientRoot.height; radius: Number(renderer.prop("radius", 0)) }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: renderer.subscribed("hover")
    onClicked: function(mouse) { if (renderer.subscribed("click")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", { x: mouse.x, y: mouse.y }) }
    onPositionChanged: function(mouse) { if (renderer.subscribed("hover")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", { x: mouse.x, y: mouse.y }) }
  }
}
