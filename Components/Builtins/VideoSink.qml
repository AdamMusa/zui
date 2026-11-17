import QtQuick
import QtMultimedia

// VideoSink is the one creatable type among QtMultimedia's device and format types. It
// receives frames from a media player or capture session without drawing them, which is
// what an application needs to know a camera is producing frames, and at what size,
// without putting a VideoOutput on screen.
Item {
  id: root
  required property var renderer
  readonly property alias sink: nativeSink
  readonly property var sourceItem: renderer ? renderer.findRenderedItem(renderer.prop("source", "")) : null
  property int frameIndex: 0
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

  VideoSink {
    id: nativeSink
    // QML's VideoSink is QQuickVideoSink, which re-declares videoFrameChanged with no
    // parameters, shadowing QVideoSink's videoFrameChanged(QVideoFrame). QVideoSink has no
    // videoFrame property either, so the frame itself is unreachable from QML in 6.8.3:
    // what this type can honestly report is that a frame arrived, and at what size.
    onVideoFrameChanged: {
      root.frameIndex++
      root.send("frame", { index: root.frameIndex,
        width: Number(nativeSink.videoSize.width), height: Number(nativeSink.videoSize.height) })
    }
    onVideoSizeChanged: root.send("size_change", { width: Number(nativeSink.videoSize.width), height: Number(nativeSink.videoSize.height) })
    onSubtitleTextChanged: root.send("subtitle", { text: String(nativeSink.subtitleText) })
  }
  Component.onCompleted: connectSource()
  onSourceItemChanged: connectSource()
}
