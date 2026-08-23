import QtQuick
import QtQuick.Effects

Item {
  required property var renderer
  implicitWidth: Number(renderer.prop("width", 240)); implicitHeight: Number(renderer.prop("height", 160))
  Item { id: sourceHost; anchors.fill: parent; Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent } }
  ShaderEffectSource { id: sourceTexture; anchors.fill: parent; sourceItem: sourceHost; hideSource: true; visible: false }
  MultiEffect {
    anchors.fill: parent; source: sourceTexture; shadowEnabled: true
    shadowBlur: Number(renderer.prop("blur", 1)); blurMax: Number(renderer.prop("maximum", 32)); blurMultiplier: Number(renderer.prop("multiplier", 1))
    shadowHorizontalOffset: 0; shadowVerticalOffset: 0; shadowColor: renderer.prop("color", renderer.foreground)
    shadowOpacity: Number(renderer.prop("opacity", 1)); shadowScale: Number(renderer.prop("scale", 1)); autoPaddingEnabled: renderer.prop("auto_padding", true) !== false
  }
}
