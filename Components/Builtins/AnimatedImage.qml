import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

AnimatedImage {
  required property var renderer
      source: String(renderer.prop("source", ""))
      width: Number(renderer.prop("width", sourceSize.width > 0 ? sourceSize.width : 120))
      height: Number(renderer.prop("height", sourceSize.height > 0 ? sourceSize.height : 120))
      fillMode: {
        var mode = String(renderer.prop("fill_mode", "contain"))
        if (mode === "cover") return Image.PreserveAspectCrop
        if (mode === "stretch") return Image.Stretch
        if (mode === "tile") return Image.Tile
        if (mode === "tile_horizontal") return Image.TileHorizontally
        if (mode === "tile_vertical") return Image.TileVertically
        if (mode === "pad") return Image.Pad
        return Image.PreserveAspectFit
      }
      playing: renderer.prop("playing", true) !== false
      paused: renderer.prop("paused", false) === true
      speed: Number(renderer.prop("speed", 1))
      asynchronous: renderer.prop("asynchronous", true) !== false
      cache: renderer.prop("cache", true) !== false
      mirror: renderer.prop("mirror", false) === true
      smooth: renderer.prop("smooth", true) !== false
      onCurrentFrameChanged: {
        if (renderer.subscribed("frame")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "frame", { value: currentFrame, count: frameCount })
      }
      onStatusChanged: {
        if (renderer.subscribed("status")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "status", { value: status })
        if (status === AnimatedImage.Ready && renderer.subscribed("loaded")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "loaded", { width: sourceSize.width, height: sourceSize.height, frames: frameCount })
        if (status === AnimatedImage.Error) renderer.componentError("animated_image_load_failed", "Unable to load the declared animated image", { source: String(source) })
      }
    }
