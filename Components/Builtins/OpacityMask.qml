import QtQuick
import QtQuick.Effects

Item {
  required property var renderer
  implicitWidth: Number(renderer.prop("width", 240))
  implicitHeight: Number(renderer.prop("height", 160))
  Item { id: sourceHost; anchors.fill: parent; Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent } }
  ShaderEffectSource { id: sourceTexture; anchors.fill: parent; sourceItem: sourceHost; hideSource: true; visible: false }
  MultiEffect {
    anchors.fill: parent
    source: sourceTexture
    maskEnabled: true
    maskSource: renderer.findRenderedItem(renderer.prop("mask_source", ""))
    maskThresholdMin: Number(renderer.prop("threshold_min", 0))
    maskSpreadAtMin: Number(renderer.prop("spread_min", 0))
    maskThresholdMax: Number(renderer.prop("threshold_max", 1))
    maskSpreadAtMax: Number(renderer.prop("spread_max", 0))
    maskInverted: renderer.prop("inverted", false) === true
  }
}
