import QtQuick
import Qt5Compat.GraphicalEffects

Item {
  id: gradientRoot
  required property var renderer
  property var createdStops: []
  implicitWidth: Number(renderer.prop("width", 240))
  implicitHeight: Number(renderer.prop("height", 160))

  readonly property bool masked: !!(renderer.node && renderer.node.children && renderer.node.children.length > 0)

  function gradientColors() {
    var colors = renderer.prop("colors", ["white", "black"])
    return Array.isArray(colors) && colors.length > 0 ? colors : ["white", "black"]
  }

  function stopPosition(index, count) {
    var stops = renderer.prop("stops", [])
    return Array.isArray(stops) && index < stops.length ? Number(stops[index]) : (count <= 1 ? 0 : index / (count - 1))
  }

  function rebuildStops() {
    for (var oldIndex = 0; oldIndex < createdStops.length; oldIndex++) createdStops[oldIndex].destroy()
    var colors = gradientColors()
    var replacements = []
    for (var index = 0; index < colors.length; index++) {
      replacements.push(stopFactory.createObject(gradientRoot, {
        position: stopPosition(index, colors.length), color: String(colors[index])
      }))
    }
    createdStops = replacements
  }

  Component { id: stopFactory; GradientStop {} }
  Connections { target: renderer; function onNodeChanged() { gradientRoot.rebuildStops() } }
  Component.onCompleted: rebuildStops()

  Item {
    id: maskHost
    anchors.fill: parent
    visible: false
    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  }

  RadialGradient {
    anchors.fill: parent
    source: gradientRoot.masked ? maskHost : undefined
    horizontalOffset: Number(renderer.prop("horizontal_offset", 0))
    verticalOffset: Number(renderer.prop("vertical_offset", 0))
    horizontalRadius: Number(renderer.prop("horizontal_radius", gradientRoot.width))
    verticalRadius: Number(renderer.prop("vertical_radius", gradientRoot.height))
    angle: Number(renderer.prop("angle", 0))
    cached: renderer.prop("cached", false) === true
    gradient: Gradient { stops: gradientRoot.createdStops }
  }
}
