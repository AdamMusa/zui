import QtQuick
import QtQuick.Timeline

// QtQuick.Timeline/Timeline. Maps a frame range onto the keyframed properties of
// any number of targets, so one scrubbable number can drive a whole scene.
//
// `keyframe_groups` and `animations` are read-only Qt list properties: they
// append but never reassign, so a changed reference list rebuilds the native
// timeline rather than leaving stale groups behind. The frame range, the
// current frame and `enabled` stay bound across a rebuild.
Item {
  id: timelineRoot
  property var renderer: null
  property var nativeTimeline: null
  property string appliedComposition: ""

  function referencedIds(name) {
    var value = renderer ? renderer.prop(name, []) : []
    var ids = Array.isArray(value) ? value : (String(value || "") === "" ? [] : [value])
    var names = []
    for (var index = 0; index < ids.length; index++) {
      var controlId = String(ids[index] || "")
      if (controlId !== "") names.push(controlId)
    }
    return names
  }

  function resolveAll(ids, handle, resolvedIds) {
    var resolved = []
    for (var index = 0; index < ids.length; index++) {
      var host = renderer.findRenderedItem(ids[index])
      var value = host ? host[handle] : null
      if (value) {
        resolved.push(value)
        resolvedIds.push(ids[index])
      }
    }
    return resolved
  }

  function send(name, payload) {
    if (renderer && renderer.subscribed(name)) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }

  function rebuild() {
    if (!renderer) return
    var groupIds = referencedIds("keyframe_groups")
    var animationIds = referencedIds("animations")
    var resolvedIds = []
    var groups = resolveAll(groupIds, "nativeKeyframeGroup", resolvedIds)
    var animations = resolveAll(animationIds, "nativeTimelineAnimation", resolvedIds)
    // A reference that has not rendered yet keeps the signature different, so
    // the next node revision picks it up instead of caching a partial timeline.
    var signature = groupIds.join(",") + ";" + animationIds.join(",") + "|" + resolvedIds.join(",")
    if (signature === appliedComposition && nativeTimeline) return
    var previous = nativeTimeline
    nativeTimeline = null
    if (previous) previous.destroy()
    var created = timelineFactory.createObject(timelineRoot)
    for (var group = 0; group < groups.length; group++) created.keyframeGroups.push(groups[group])
    for (var animation = 0; animation < animations.length; animation++) created.animations.push(animations[animation])
    appliedComposition = signature
    nativeTimeline = created
  }

  Component {
    id: timelineFactory
    Timeline {
      id: createdTimeline
      // A timeline still being built is not the live one yet, so its initial
      // property assignments are not reported as frames the application moved.
      readonly property bool live: timelineRoot.nativeTimeline === createdTimeline
      onCurrentFrameChanged: if (live) timelineRoot.send("frame_change", { value: createdTimeline.currentFrame })
      onEnabledChanged: if (live) timelineRoot.send("enable_change", { value: createdTimeline.enabled })
    }
  }

  Binding {
    target: timelineRoot.nativeTimeline
    property: "startFrame"
    value: Number(timelineRoot.renderer ? timelineRoot.renderer.prop("start_frame", 0) : 0)
    when: timelineRoot.nativeTimeline !== null
  }
  Binding {
    target: timelineRoot.nativeTimeline
    property: "endFrame"
    value: Number(timelineRoot.renderer ? timelineRoot.renderer.prop("end_frame", 0) : 0)
    when: timelineRoot.nativeTimeline !== null
  }
  Binding {
    target: timelineRoot.nativeTimeline
    property: "currentFrame"
    value: Number(timelineRoot.renderer ? timelineRoot.renderer.prop("current_frame", 0) : 0)
    when: timelineRoot.nativeTimeline !== null
  }
  Binding {
    target: timelineRoot.nativeTimeline
    property: "enabled"
    value: timelineRoot.renderer ? timelineRoot.renderer.prop("enabled", true) !== false : true
    when: timelineRoot.nativeTimeline !== null
  }

  Connections {
    target: timelineRoot.renderer
    function onNodeChanged() { timelineRoot.rebuild() }
  }
  Component.onCompleted: { rebuild(); Qt.callLater(rebuild) }
}
