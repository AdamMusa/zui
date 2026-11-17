import QtQuick
import Qt5Compat.GraphicalEffects

Item {
  id: blendRoot
  required property var renderer
  readonly property var blendModes: [
    "normal", "addition", "average", "color", "colorburn", "colordodge", "darken", "darkercolor",
    "difference", "divide", "exclusion", "hardlight", "hue", "lighten", "lightercolor", "lightness",
    "multiply", "negation", "saturation", "screen", "subtract", "softlight"
  ]
  implicitWidth: Number(renderer.prop("width", 240))
  implicitHeight: Number(renderer.prop("height", 160))

  // Qt matches its blend modes case-insensitively but without separators, so
  // "color_burn" and "colorBurn" both have to reach Qt as "colorburn". An
  // unknown mode is passed through unchanged: Qt paints it solid red, which is
  // a louder failure than quietly compositing as "normal".
  function blendMode() {
    var requested = String(renderer.prop("mode", "normal"))
    var normalized = requested.replace(/_/g, "")
    if (blendModes.indexOf(normalized.toLowerCase()) < 0)
      renderer.componentError("blend_mode_unsupported", "Unknown blend mode: " + requested, { mode: requested })
    return normalized
  }

  function foregroundItem() {
    var target = String(renderer.prop("foreground_source", ""))
    if (target === "") return null
    var resolved = renderer.findRenderedItem(target)
    if (!resolved) renderer.componentError("foreground_source_missing", "No rendered item with id " + target, { foreground_source: target })
    return resolved
  }

  Item {
    id: sourceHost
    anchors.fill: parent
    visible: false
    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  }

  Blend {
    anchors.fill: parent
    source: sourceHost
    foregroundSource: blendRoot.foregroundItem()
    mode: blendRoot.blendMode()
    cached: renderer.prop("cached", false) === true
  }
}
