import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import QtMultimedia
import QtQuick.VectorImage
import "../../Theme"
import "../../Controls" as ZuiControls

VectorImage {
  required property var renderer
      source: renderer.assetUrl(renderer.prop("source", ""))
      width: Number(renderer.prop("width", 120))
      height: Number(renderer.prop("height", 120))
      fillMode: {
        var mode = String(renderer.prop("fill_mode", "contain"))
        if (mode === "cover") return VectorImage.PreserveAspectCrop
        if (mode === "stretch") return VectorImage.Stretch
        if (mode === "none") return VectorImage.NoResize
        return VectorImage.PreserveAspectFit
      }
      preferredRendererType: String(renderer.prop("renderer", "geometry")) === "curve"
        ? VectorImage.CurveRenderer : VectorImage.GeometryRenderer
      assumeTrustedSource: renderer.prop("trusted", false) === true
      asynchronousShapes: renderer.prop("asynchronous_shapes", false) === true
      animations.loops: Number(renderer.prop("animation_loops", 1))
      animations.paused: renderer.prop("animation_paused", false) === true
      onSourceChanged: {
        if (renderer.subscribed("source_change")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "source_change", { value: source })
      }
    }
