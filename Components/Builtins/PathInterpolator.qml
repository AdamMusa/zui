import QtQuick
import "Support" as Support

Item {
  id: interpolatorRoot
  required property var renderer
  property var createdElements: []
  property string appliedElementKey: ""
  property string handledProgressKey: ""
  implicitWidth: 0
  implicitHeight: 0

  function requestedSegments() {
    var segments = renderer.prop("segments", null)
    return Array.isArray(segments) && segments.length > 0 ? segments : null
  }

  function rebuildElements() {
    var segments = requestedSegments()
    var key = JSON.stringify({ segments: segments, data: String(renderer.prop("data", "")) })
    if (key === appliedElementKey) return false
    appliedElementKey = key
    nativePath.pathElements = []
    for (var index = 0; index < createdElements.length; index++) createdElements[index].destroy()
    if (!segments) {
      createdElements = [svgFactory.createObject(interpolatorRoot, { path: String(renderer.prop("data", "")) })]
      nativePath.pathElements = createdElements
      return true
    }
    var built = segmentFactory.build(interpolatorRoot, segments)
    createdElements = built.elements
    nativePath.pathElements = createdElements
    if (built.rejected.length > 0)
      renderer.componentError("path_segment_rejected",
        "path_interpolator accepts only the Qt path element types", { types: built.rejected })
    return true
  }

  function publishProgress(force) {
    var progress = Math.max(0, Math.min(1, Number(renderer.prop("progress", 0))))
    var key = appliedElementKey + "\u001f" + String(progress)
    if (!force && key === handledProgressKey) return
    handledProgressKey = key
    nativeInterpolator.progress = progress
    if (!renderer.subscribed("interpolate")) return
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "interpolate", {
      progress: nativeInterpolator.progress, x: nativeInterpolator.x,
      y: nativeInterpolator.y, angle: nativeInterpolator.angle
    })
  }

  function synchronize() {
    publishProgress(rebuildElements())
  }

  Component { id: svgFactory; PathSvg {} }
  Support.PathSegmentFactory { id: segmentFactory }

  Path {
    id: nativePath
    startX: Number(renderer.prop("start_x", 0))
    startY: Number(renderer.prop("start_y", 0))
  }

  PathInterpolator {
    id: nativeInterpolator
    path: nativePath
  }

  Component.onCompleted: synchronize()
  Connections { target: renderer; function onNodeChanged() { interpolatorRoot.synchronize() } }
}
