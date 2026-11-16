import QtQuick
import QtMultimedia

// VideoSink is the one creatable type among QtMultimedia's device and format types. It
// receives frames from a media player or capture session without drawing them, which is
// what an application needs to know a camera is producing frames, and at what size and
// format, without putting a VideoOutput on screen.
Item {
  id: root
  required property var renderer
  readonly property alias sink: nativeSink
  readonly property var sourceItem: renderer ? renderer.findRenderedItem(renderer.prop("source", "")) : null
  visible: false

  function send(name, payload) {
    if (renderer.subscribed(name)) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }
  function connectSource() {
    if (!sourceItem) {
      if (String(renderer.prop("source", "")) !== "")
        renderer.componentError("video_sink_source_missing", "The media player or capture session named by source was not found",
          { source: String(renderer.prop("source", "")) })
      return
    }
    if (sourceItem.mediaPlayer !== undefined) { sourceItem.mediaPlayer.videoSink = nativeSink; return }
    if (sourceItem.captureSession !== undefined) { sourceItem.captureSession.videoSink = nativeSink; return }
    renderer.componentError("video_sink_source_invalid", "source must name a media_player or capture_session",
      { source: String(renderer.prop("source", "")) })
  }
  function publishFrame() {
    var frame = nativeSink.videoFrame
    send("frame", {
      width: Number(nativeSink.videoSize.width), height: Number(nativeSink.videoSize.height),
      valid: frame && frame.valid === true,
      pixel_format: frame ? Number(frame.pixelFormat) : 0,
      start_time: frame ? Number(frame.startTime) : 0,
      end_time: frame ? Number(frame.endTime) : 0
    })
  }

  VideoSink {
    id: nativeSink
    onVideoFrameChanged: root.publishFrame()
    onVideoSizeChanged: root.send("size_change", { width: Number(nativeSink.videoSize.width), height: Number(nativeSink.videoSize.height) })
    onSubtitleTextChanged: root.send("subtitle", { text: String(nativeSink.subtitleText) })
  }
  Component.onCompleted: connectSource()
  onSourceItemChanged: connectSource()
}
