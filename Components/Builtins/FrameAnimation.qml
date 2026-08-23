import QtQuick

Item {
  id: frameRoot
  property var renderer: null
  FrameAnimation {
    id: nativeFrame
    running: renderer && renderer.prop("running", true) !== false
    paused: renderer && renderer.prop("paused", false) === true
    onTriggered: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "frame", { frame: currentFrame, frame_time: frameTime, smooth_frame_time: smoothFrameTime, elapsed_time: elapsedTime })
    onRunningChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, running ? "start" : "stop", {})
  }
}
