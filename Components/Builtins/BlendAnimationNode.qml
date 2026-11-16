import QtQuick
import QtQuick.Timeline.BlendTrees

// QtQuick.Timeline.BlendTrees/BlendAnimationNode. Mixes two blend-tree inputs by
// weight, so a scene can cross-fade between two keyframed animations instead of
// cutting between them.
//
// `source1` and `source2` reference blend-tree nodes by control id. Nodes can be
// chained: this node also publishes `nativeBlendTreeNode`.
Item {
  id: blendAnimationNodeRoot
  property var renderer: null
  readonly property var nativeBlendTreeNode: nativeNode

  readonly property var firstSource: nativeHandle(renderer ? renderer.prop("source1", "") : "", "nativeBlendTreeNode")
  readonly property var secondSource: nativeHandle(renderer ? renderer.prop("source2", "") : "", "nativeBlendTreeNode")

  function nativeHandle(controlId, handle) {
    var name = String(controlId || "")
    if (!renderer || name === "") return null
    var host = renderer.findRenderedItem(name)
    if (!host) return null
    var value = host[handle]
    return value === undefined ? null : value
  }

  function send(name, payload) {
    if (renderer && renderer.subscribed(name)) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }

  BlendAnimationNode {
    id: nativeNode
    source1: blendAnimationNodeRoot.firstSource
    source2: blendAnimationNodeRoot.secondSource
    weight: Number(blendAnimationNodeRoot.renderer ? blendAnimationNodeRoot.renderer.prop("weight", 0.5) : 0.5)
    outputEnabled: blendAnimationNodeRoot.renderer
      ? blendAnimationNodeRoot.renderer.prop("output_enabled", false) === true
      : false

    onFrameDataChanged: blendAnimationNodeRoot.send("frame_change", {})
  }
}
