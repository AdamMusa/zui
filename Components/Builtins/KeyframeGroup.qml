import QtQuick
import QtQuick.Timeline

// QtQuick.Timeline/KeyframeGroup. The keyframes one property of one target
// passes through, so several properties can share a timeline.
//
// `keyframes` is a read-only Qt list property: it appends but never reassigns,
// so a changed reference list rebuilds the native group rather than leaving
// stale keyframes behind. A timeline references its groups by control id and
// reads `nativeKeyframeGroup` from each.
Item {
  id: keyframeGroupRoot
  property var renderer: null
  property var nativeKeyframeGroup: null
  property string appliedKeyframes: ""

  readonly property var targetItem: renderer ? renderer.findRenderedItem(renderer.prop("target", "")) : null

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

  function rebuild() {
    if (!renderer) return
    var ids = referencedIds("keyframes")
    var resolved = []
    var resolvedIds = []
    for (var index = 0; index < ids.length; index++) {
      var host = renderer.findRenderedItem(ids[index])
      var keyframe = host ? host.nativeKeyframe : null
      if (keyframe) {
        resolved.push(keyframe)
        resolvedIds.push(ids[index])
      }
    }
    // A keyframe that has not rendered yet keeps the signature different, so
    // the next node revision picks it up instead of caching a partial group.
    var signature = ids.join(",") + "|" + resolvedIds.join(",")
    if (signature === appliedKeyframes && nativeKeyframeGroup) return
    var previous = nativeKeyframeGroup
    nativeKeyframeGroup = null
    if (previous) previous.destroy()
    var created = keyframeGroupFactory.createObject(keyframeGroupRoot)
    for (var slot = 0; slot < resolved.length; slot++) created.keyframes.push(resolved[slot])
    appliedKeyframes = signature
    nativeKeyframeGroup = created
  }

  Component { id: keyframeGroupFactory; KeyframeGroup {} }

  Binding {
    target: keyframeGroupRoot.nativeKeyframeGroup
    property: "target"
    value: keyframeGroupRoot.targetItem
    when: keyframeGroupRoot.nativeKeyframeGroup !== null
  }
  Binding {
    target: keyframeGroupRoot.nativeKeyframeGroup
    property: "property"
    value: String(keyframeGroupRoot.renderer ? keyframeGroupRoot.renderer.prop("property", "") : "")
    when: keyframeGroupRoot.nativeKeyframeGroup !== null
  }
  Binding {
    target: keyframeGroupRoot.nativeKeyframeGroup
    property: "keyframeSource"
    value: keyframeGroupRoot.renderer ? keyframeGroupRoot.renderer.assetUrl(keyframeGroupRoot.renderer.prop("keyframe_source", "")) : ""
    when: keyframeGroupRoot.nativeKeyframeGroup !== null && keyframeGroupRoot.renderer
      ? keyframeGroupRoot.renderer.hasProp("keyframe_source")
      : false
  }

  Connections {
    target: keyframeGroupRoot.renderer
    function onNodeChanged() { keyframeGroupRoot.rebuild() }
  }
  Component.onCompleted: { rebuild(); Qt.callLater(rebuild) }
}
