import QtQuick
import QtQuick.Effects

Item {
  id: effectRoot
  required property var renderer
  implicitWidth: Number(renderer.prop("width", 240))
  implicitHeight: Number(renderer.prop("height", 160))

  // MultiEffect.source takes any Item, not only this component's own children.
  // A `source_item` names one by id so an effect can be applied to content that
  // already lives elsewhere in the tree.
  function effectSource() {
    var target = String(renderer.prop("source_item", ""))
    if (target === "") return sourceTexture
    var resolved = renderer.findRenderedItem(target)
    if (resolved) return resolved
    renderer.componentError("source_item_missing", "No rendered item with id " + target, { source_item: target })
    return sourceTexture
  }

  function maskItem() {
    var target = String(renderer.prop("mask_source", ""))
    if (target === "") return null
    var resolved = renderer.findRenderedItem(target)
    if (!resolved) renderer.componentError("mask_source_missing", "No rendered item with id " + target, { mask_source: target })
    return resolved
  }

  Item {
    id: sourceHost
    anchors.fill: parent
    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  }
  ShaderEffectSource { id: sourceTexture; anchors.fill: parent; sourceItem: sourceHost; hideSource: true; visible: false }

  MultiEffect {
    id: nativeEffect
    anchors.fill: parent
    source: effectRoot.effectSource()
    brightness: Number(renderer.prop("brightness", 0))
    contrast: Number(renderer.prop("contrast", 0))
    saturation: Number(renderer.prop("saturation", 0))
    colorization: Number(renderer.prop("colorization", 0))
    colorizationColor: renderer.prop("colorization_color", "white")
    blurEnabled: renderer.prop("blur_enabled", false) === true
    blur: Number(renderer.prop("blur", 0))
    blurMax: Number(renderer.prop("blur_max", 32))
    blurMultiplier: Number(renderer.prop("blur_multiplier", 1))
    shadowEnabled: renderer.prop("shadow_enabled", false) === true
    shadowOpacity: Number(renderer.prop("shadow_opacity", 1))
    shadowBlur: Number(renderer.prop("shadow_blur", 1))
    shadowHorizontalOffset: Number(renderer.prop("shadow_horizontal_offset", 0))
    shadowVerticalOffset: Number(renderer.prop("shadow_vertical_offset", 0))
    shadowColor: renderer.prop("shadow_color", "black")
    shadowScale: Number(renderer.prop("shadow_scale", 1))
    maskEnabled: renderer.prop("mask_enabled", false) === true
    maskSource: effectRoot.maskItem()
    maskThresholdMin: Number(renderer.prop("mask_threshold_min", 0))
    maskSpreadAtMin: Number(renderer.prop("mask_spread_at_min", 0))
    maskThresholdMax: Number(renderer.prop("mask_threshold_max", 1))
    maskSpreadAtMax: Number(renderer.prop("mask_spread_at_max", 0))
    maskInverted: renderer.prop("mask_inverted", false) === true
    autoPaddingEnabled: renderer.prop("auto_padding", true) !== false
    // Qt reads paddingRect's x/y as the left/top padding and its width/height
    // as the right/bottom padding, which is why these four edges map onto a
    // rect rather than onto an origin and a size.
    paddingRect: Qt.rect(Number(renderer.prop("padding_left", 0)), Number(renderer.prop("padding_top", 0)), Number(renderer.prop("padding_right", 0)), Number(renderer.prop("padding_bottom", 0)))
    onItemRectChanged: if (renderer.subscribed("geometry")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "geometry", { x: itemRect.x, y: itemRect.y, width: itemRect.width, height: itemRect.height })
    onShaderChanged: if (renderer.subscribed("shader_change")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "shader_change", { fragment: fragmentShader, vertex: vertexShader })
  }
}
