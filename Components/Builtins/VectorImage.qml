import QtQuick
import QtQuick.VectorImage
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

VectorImage {
  id: vectorRoot
  required property var renderer

  function synchronizeCapabilities() {
    var trusted = renderer.prop("trusted", false) === true
    if (vectorRoot["assumeTrustedSource"] !== undefined)
      vectorRoot["assumeTrustedSource"] = trusted
    else if (trusted)
      renderer.componentError("trusted_vector_unsupported",
        "The installed Qt version does not support trusted vector sources", {})

    var asynchronous = renderer.prop("asynchronous_shapes", false) === true
    if (vectorRoot["asynchronousShapes"] !== undefined)
      vectorRoot["asynchronousShapes"] = asynchronous
    else if (asynchronous)
      renderer.componentError("asynchronous_vector_unsupported",
        "The installed Qt version does not support asynchronous vector shapes", {})

    var controller = vectorRoot["animations"]
    var loops = Number(renderer.prop("animation_loops", 1))
    var paused = renderer.prop("animation_paused", false) === true
    if (controller === undefined || controller === null) {
      if (loops !== 1 || paused)
        renderer.componentError("vector_animation_unsupported",
          "The installed Qt version does not support animated vector images", {})
      return
    }
    controller.loops = loops
    controller.paused = paused
  }

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
  onSourceChanged: {
    if (renderer.subscribed("source_change"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "source_change", { value: source })
  }
  Component.onCompleted: synchronizeCapabilities()
  Connections {
    target: vectorRoot.renderer
    function onNodeChanged() { vectorRoot.synchronizeCapabilities() }
  }
}
