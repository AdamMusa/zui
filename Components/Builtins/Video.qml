import QtQuick
import QtMultimedia
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Video {
  id: videoRoot
  required property var renderer

  function synchronizeCapabilities() {
    var mirroredValue = renderer.prop("mirrored", false) === true
    if (videoRoot["mirrored"] !== undefined)
      videoRoot["mirrored"] = mirroredValue
    else if (mirroredValue)
      renderer.componentError("video_mirroring_unsupported",
        "The installed Qt version does not support mirrored video output", {})
  }

  source: String(renderer.prop("source", ""))
  implicitWidth: Number(renderer.prop("width", 640))
  implicitHeight: Number(renderer.prop("height", 360))
  autoPlay: renderer.prop("auto_play", false) === true
  loops: Number(renderer.prop("loops", 1))
  volume: Math.max(0, Math.min(1, Number(renderer.prop("volume", 1))))
  muted: renderer.prop("muted", false) === true
  playbackRate: Number(renderer.prop("playback_rate", 1))
  orientation: Number(renderer.prop("orientation", 0))
  fillMode: {
    var mode = String(renderer.prop("fill_mode", "contain"))
    if (mode === "cover") return VideoOutput.PreserveAspectCrop
    if (mode === "stretch") return VideoOutput.Stretch
    return VideoOutput.PreserveAspectFit
  }
  onPlaying: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "play", {})
  onPaused: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "pause", {})
  onStopped: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "stop", {})
  onErrorOccurred: function(error, message) {
    renderer.componentError("video_playback_failed", message, { native_code: error, source: String(source) })
  }
  onPositionChanged: {
    if (renderer.subscribed("position")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "position", { value: position, duration: duration })
  }
  onDurationChanged: {
    if (renderer.subscribed("duration")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "duration", { value: duration })
  }
  Component.onCompleted: synchronizeCapabilities()
  Connections {
    target: videoRoot.renderer
    function onNodeChanged() { videoRoot.synchronizeCapabilities() }
  }
}
