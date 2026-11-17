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

  LinearGradient {
    anchors.fill: parent
    source: gradientRoot.masked ? maskHost : undefined
    start: Qt.point(Number(renderer.prop("start_x", 0)), Number(renderer.prop("start_y", 0)))
    end: Qt.point(Number(renderer.prop("end_x", 0)), Number(renderer.prop("end_y", gradientRoot.height)))
    cached: renderer.prop("cached", false) === true
    gradient: Gradient { stops: gradientRoot.createdStops }
  }
}
