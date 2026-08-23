import QtQuick
import QtMultimedia

Item {
  id: audioRoot

  required property var renderer
  property real appliedSeekRevision: -1
  property real lastReportedPosition: -1000

  implicitWidth: 0
  implicitHeight: 0

  function send(name, payload) {
    if (renderer.subscribed(name))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }

  function applySeek(force) {
    var revision = Number(renderer.prop("seek_revision", 0))
    if (!force && revision === appliedSeekRevision) return
    appliedSeekRevision = revision
    audioPlayer.setPosition(Math.max(0, Number(renderer.prop("position", 0))))
  }

  function syncPlayback() {
    applySeek(false)
    var requested = String(renderer.prop("playback", ""))
    if (requested === "play") audioPlayer.play()
    else if (requested === "pause") audioPlayer.pause()
    else if (requested === "stop") audioPlayer.stop()
  }

  MediaPlayer {
    id: audioPlayer
    source: renderer.assetUrl(renderer.prop("source", ""))
    autoPlay: renderer.prop("auto_play", false) === true
    loops: Number(renderer.prop("loops", 1))
    playbackRate: Number(renderer.prop("playback_rate", 1))

    audioOutput: AudioOutput {
      volume: Math.max(0, Math.min(1, Number(renderer.prop("volume", 1))))
      muted: renderer.prop("muted", false) === true
    }

    onSourceChanged: Qt.callLater(audioRoot.syncPlayback)

    onPlaybackStateChanged: function(playbackState) {
      var eventName = playbackState === MediaPlayer.PlayingState ? "play"
        : (playbackState === MediaPlayer.PausedState ? "pause" : "stop")
      audioRoot.send(eventName, { position: audioPlayer.position, duration: audioPlayer.duration })
    }

    onMediaStatusChanged: function(mediaStatus) {
      audioRoot.send("status", { value: mediaStatus, position: audioPlayer.position, duration: audioPlayer.duration })
      if (mediaStatus === MediaPlayer.LoadedMedia) {
        audioRoot.applySeek(true)
        audioRoot.syncPlayback()
        audioRoot.send("loaded", { duration: audioPlayer.duration, source: audioPlayer.source })
      } else if (mediaStatus === MediaPlayer.EndOfMedia) {
        audioRoot.send("end", { position: audioPlayer.position, duration: audioPlayer.duration })
      }
    }

    onErrorOccurred: function(error, message) {
      renderer.componentError("audio_playback_failed", message, { native_code: error, source: String(audioPlayer.source) })
    }

    onPositionChanged: {
      if (Math.abs(audioPlayer.position - audioRoot.lastReportedPosition) < 180
          && audioPlayer.position !== audioPlayer.duration) return
      audioRoot.lastReportedPosition = audioPlayer.position
      audioRoot.send("position", { value: audioPlayer.position, duration: audioPlayer.duration })
    }

    onDurationChanged: audioRoot.send("duration", { value: audioPlayer.duration })
  }

  Component.onCompleted: syncPlayback()

  Connections {
    target: renderer
    function onNodeChanged() { audioRoot.syncPlayback() }
  }
}
