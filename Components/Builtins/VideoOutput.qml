import QtQuick
import QtMultimedia

VideoOutput {
  id: videoRoot
  property var renderer: null
  readonly property var sourceItem: renderer ? renderer.findRenderedItem(renderer.prop("source", "")) : null
  function synchronizeCapabilities() {
    var mirroredValue = renderer && renderer.prop("mirrored", false) === true
    if (videoRoot["mirrored"] !== undefined)
      videoRoot["mirrored"] = mirroredValue
    else if (mirroredValue)
      renderer.componentError("video_mirroring_unsupported",
        "The installed Qt version does not support mirrored video output", {})

    var policy = String(renderer ? renderer.prop("end_of_stream_policy", "clear") : "clear")
    if (videoRoot["endOfStreamPolicy"] !== undefined)
      videoRoot["endOfStreamPolicy"] = policy === "keep" ? VideoOutput.KeepLastFrame : VideoOutput.ClearOutput
    else if (policy === "keep")
      renderer.componentError("video_end_policy_unsupported",
        "The installed Qt version does not support keeping the final video frame", {})
  }
  implicitWidth: Number(renderer ? renderer.prop("width", 640) : 640)
  implicitHeight: Number(renderer ? renderer.prop("height", 360) : 360)
  fillMode: {
    var mode = String(renderer ? renderer.prop("fill_mode", "contain") : "contain")
    if (mode === "cover") return VideoOutput.PreserveAspectCrop
    if (mode === "stretch") return VideoOutput.Stretch
    return VideoOutput.PreserveAspectFit
  }
  orientation: Number(renderer ? renderer.prop("orientation", 0) : 0)
  function connectSource() {
    if (!sourceItem) return
    if (sourceItem.mediaPlayer !== undefined) sourceItem.mediaPlayer.videoOutput = videoRoot
    else if (sourceItem.captureSession !== undefined) sourceItem.captureSession.videoOutput = videoRoot
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "source_change", { value: renderer.prop("source", "") })
  }
  Component.onCompleted: {
    connectSource()
    synchronizeCapabilities()
  }
  onSourceItemChanged: connectSource()
  Connections {
    target: renderer
    function onNodeChanged() { videoRoot.synchronizeCapabilities() }
  }
  Connections {
    target: videoSink
    function onVideoFrameChanged() {
      if (renderer.subscribed("frame"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "frame", {})
    }
  }
}
