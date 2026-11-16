import QtQuick
import QtQuick.Timeline
import QtQuick.Timeline.BlendTrees

// QtQuick.Timeline.BlendTrees/TimelineAnimationNode. Turns one timeline and one
// of its animations into a blend-tree input, so several animations of the same
// timeline can be mixed instead of played one after another.
//
// `timeline` and `animation` reference a timeline and a timeline_animation
// component by control id. A blend_animation_node references this node the same
// way and reads `nativeBlendTreeNode` from it.
Item {
  id: timelineAnimationNodeRoot
  property var renderer: null
  readonly property var nativeBlendTreeNode: nativeNode

  readonly property var sourceTimeline: nativeHandle(renderer ? renderer.prop("timeline", "") : "", "nativeTimeline")
  readonly property var sourceAnimation: nativeHandle(renderer ? renderer.prop("animation", "") : "", "nativeTimelineAnimation")

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

  TimelineAnimationNode {
    id: nativeNode
    timeline: timelineAnimationNodeRoot.sourceTimeline
    animation: timelineAnimationNodeRoot.sourceAnimation
    outputEnabled: timelineAnimationNodeRoot.renderer
      ? timelineAnimationNodeRoot.renderer.prop("output_enabled", false) === true
      : false

    onCurrentFrameChanged: timelineAnimationNodeRoot.send("frame_change", { value: nativeNode.currentFrame })
  }
}
