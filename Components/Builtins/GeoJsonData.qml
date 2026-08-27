import QtQuick
import QtLocation

Item {
  id: root
  required property var renderer
  property int handledCommandRevision: -1
  visible: false

  function processCommand() {
    var revision = Number(renderer.prop("command_revision", 0))
    if (revision === handledCommandRevision) return
    var first = handledCommandRevision < 0
    handledCommandRevision = revision
    if (first && revision <= 0) return
    var command = String(renderer.prop("command", "open"))
    if (command === "clear") nativeData.clear()
    else if (command === "open") {
      var source = String(renderer.prop("source", ""))
      if (source !== "" && !nativeData.openUrl(renderer.assetUrl(source)))
        renderer.componentError("geo_json_open_failed", "Unable to open the GeoJSON source", { source: source })
    } else if (command === "save") {
      var path = String(renderer.prop("command_path", ""))
      if (path === "" || !nativeData.saveAs(renderer.assetUrl(path)))
        renderer.componentError("geo_json_save_failed", "Unable to save the GeoJSON document", { path: path })
      else renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "saved", { path: path })
    }
  }

  GeoJsonData {
    id: nativeData
    model: root.renderer.prop("model", null)
    onModelChanged: root.renderer.bridge.sendEvent(root.renderer.surfaceName, root.renderer.controlId,
      "change", { value: model, source: String(sourceUrl) })
  }

  Component.onCompleted: {
    var source = String(renderer.prop("source", ""))
    if (source !== "" && !nativeData.openUrl(renderer.assetUrl(source)))
      renderer.componentError("geo_json_open_failed", "Unable to open the GeoJSON source", { source: source })
    processCommand()
  }
  Connections { target: renderer; function onNodeChanged() { root.processCommand() } }
}
