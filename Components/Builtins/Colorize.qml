import QtQuick
import QtQuick.Effects

Item {
  required property var renderer
  implicitWidth: Number(renderer.prop("width", 240)); implicitHeight: Number(renderer.prop("height", 160))
  Item { id: sourceHost; anchors.fill: parent; Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent } }
  ShaderEffectSource { id: sourceTexture; anchors.fill: parent; sourceItem: sourceHost; hideSource: true; visible: false }
  MultiEffect {
    anchors.fill: parent; source: sourceTexture
    colorization: Number(renderer.prop("amount", 1)); colorizationColor: renderer.prop("color", "white")
    brightness: Number(renderer.prop("brightness", 0)); contrast: Number(renderer.prop("contrast", 0)); saturation: Number(renderer.prop("saturation", 0))
  }
}
