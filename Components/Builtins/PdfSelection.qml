import QtQuick
import QtQuick.Pdf
import "Support" as Support

Item {
  id: root
  required property var renderer
  property int handledCommandRevision: -1
  visible: false

  // PdfSelection.geometry is a list of QPolygonF, one polygon per selected line of text.
  // QPolygonF is an opaque value type from JavaScript, so the payload reports how many
  // line polygons the selection covers rather than inventing point coordinates for them.
  function publish() {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", {
      text: String(nativeSelection.text), page: Number(nativeSelection.page),
      hold: nativeSelection.hold === true,
      line_count: nativeSelection.geometry ? nativeSelection.geometry.length : 0
    })
  }
  function runCommand() {
    var revision = Number(renderer.prop("command_revision", 0))
    if (revision === handledCommandRevision) return
    handledCommandRevision = revision
    var command = String(renderer.prop("command", ""))
    if (command === "") return
    if (command === "clear") { nativeSelection.clear(); return }
    if (command === "select_all") { nativeSelection.selectAll(); return }
    if (command === "copy") { nativeSelection.copyToClipboard(); return }
    renderer.componentError("pdf_selection_command_rejected", "The PDF selection does not support the requested command", { command: command })
  }

  Support.PdfDocumentSource { id: documentSource; renderer: root.renderer }
  PdfSelection {
    id: nativeSelection
    document: documentSource.document
    page: Number(root.renderer.prop("page", 0))
    renderScale: Number(root.renderer.prop("zoom", 1))
    from: Qt.point(Number(root.renderer.prop("from_x", 0)), Number(root.renderer.prop("from_y", 0)))
    to: Qt.point(Number(root.renderer.prop("to_x", 0)), Number(root.renderer.prop("to_y", 0)))
    hold: root.renderer.prop("hold", false) === true
    onTextChanged: root.publish()
    onSelectedAreaChanged: root.publish()
  }
  Connections { target: root.renderer; function onNodeChanged() { root.runCommand() } }
  Component.onCompleted: runCommand()
}
