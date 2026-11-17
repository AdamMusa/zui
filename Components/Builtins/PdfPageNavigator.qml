import QtQuick
import QtQuick.Pdf

Item {
  id: root
  required property var renderer
  readonly property alias navigator: nativeNavigator
  property int handledCommandRevision: -1
  visible: false

  function send(name, payload) {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }
  function linkPayload(link) {
    if (!link) return { valid: false }
    return { valid: link.valid === true, page: Number(link.page), zoom: Number(link.zoom),
      url: String(link.url), x: Number(link.location.x), y: Number(link.location.y),
      context_before: String(link.contextBefore), context_after: String(link.contextAfter) }
  }
  function publish() {
    send("change", {
      page: Number(nativeNavigator.currentPage),
      x: Number(nativeNavigator.currentLocation.x), y: Number(nativeNavigator.currentLocation.y),
      zoom: Number(nativeNavigator.currentZoom),
      back_available: nativeNavigator.backAvailable === true,
      forward_available: nativeNavigator.forwardAvailable === true
    })
  }
  function runCommand() {
    var revision = Number(renderer.prop("command_revision", 0))
    if (revision === handledCommandRevision) return
    handledCommandRevision = revision
    var command = String(renderer.prop("command", ""))
    if (command === "") return
    var page = Number(renderer.prop("page", 0))
    var location = Qt.point(Number(renderer.prop("x", 0)), Number(renderer.prop("y", 0)))
    var zoom = Number(renderer.prop("zoom", 0))
    if (command === "jump") { nativeNavigator.jump(page, location, zoom); return }
    if (command === "update") { nativeNavigator.update(page, location, zoom); return }
    if (command === "back") { nativeNavigator.back(); return }
    if (command === "forward") { nativeNavigator.forward(); return }
    if (command === "clear") { nativeNavigator.clear(); return }
    renderer.componentError("pdf_navigator_command_rejected", "The page navigator does not support the requested command", { command: command })
  }

  // Each PDF view owns a private PdfPageNavigator that its own back/forward drive. This
  // component is the standalone navigation stack, for a custom viewer built from
  // pdf_page_image or pdf_page_view that keeps its own jump history.
  PdfPageNavigator {
    id: nativeNavigator
    onCurrentPageChanged: publishTimer.restart()
    onCurrentLocationChanged: publishTimer.restart()
    onCurrentZoomChanged: publishTimer.restart()
    onBackAvailableChanged: publishTimer.restart()
    onForwardAvailableChanged: publishTimer.restart()
    onJumped: function(current) { root.send("jump", root.linkPayload(current)) }
  }
  // One jump moves page, location, zoom and both availability flags, so coalesce the
  // five signals into a single change event.
  Timer { id: publishTimer; interval: 16; repeat: false; onTriggered: root.publish() }
  Connections { target: renderer; function onNodeChanged() { root.runCommand() } }
  Component.onCompleted: { runCommand(); publishTimer.restart() }
}
