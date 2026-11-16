import QtQuick
import Qt5Compat.GraphicalEffects

Item {
  id: adjustRoot
  required property var renderer
  implicitWidth: Number(renderer.prop("width", 240))
  implicitHeight: Number(renderer.prop("height", 160))

  function channelGamma() {
    var uniform = Number(renderer.prop("gamma", 1))
    return Qt.vector3d(Number(renderer.prop("gamma_red", uniform)),
                       Number(renderer.prop("gamma_green", uniform)),
                       Number(renderer.prop("gamma_blue", uniform)))
  }

  Item {
    id: sourceHost
    anchors.fill: parent
    visible: false
    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  }

  LevelAdjust {
    anchors.fill: parent
    source: sourceHost
    gamma: adjustRoot.channelGamma()
    minimumInput: renderer.prop("minimum_input", "#00000000")
    maximumInput: renderer.prop("maximum_input", "#ffffffff")
    minimumOutput: renderer.prop("minimum_output", "#00000000")
    maximumOutput: renderer.prop("maximum_output", "#ffffffff")
    cached: renderer.prop("cached", false) === true
  }
}
