import QtQuick
import QtQuick.Pdf
import "Support" as Support

Item {
  id: root
  required property var renderer
  readonly property var sharedDocumentItem: {
    var source = String(renderer.prop("document_source", ""))
    return source === "" ? null : renderer.findRenderedItem(source)
  }
  readonly property var activeDocument: sharedDocumentItem && sharedDocumentItem.document !== undefined
    ? sharedDocumentItem.document : ownDocument
  implicitWidth: Number(renderer.prop("width", 640))
  implicitHeight: Number(renderer.prop("height", 720))
  visible: renderer.prop("visible", true) !== false

  PdfDocument {
    id: ownDocument
    source: root.sharedDocumentItem ? "" : String(root.renderer.prop("source", ""))
    password: String(root.renderer.prop("password", ""))
    onStatusChanged: if (status === PdfDocument.Error)
      root.renderer.componentError("pdf_load_failed", String(error), { source: String(source) })
  }
  // PdfPageView renders a single page at a time and, unlike the other two views, has no
  // pageRotation: it exposes zoomEnabled for its own pinch and wheel zoom instead.
  PdfPageView {
    id: nativeView
    anchors.fill: parent
    document: root.activeDocument
    renderScale: Number(root.renderer.prop("zoom", 1))
    zoomEnabled: root.renderer.prop("zoom_enabled", true) !== false
    searchString: String(root.renderer.prop("search", ""))
    onStatusChanged: root.renderer.bridge.sendEvent(root.renderer.surfaceName, root.renderer.controlId, "status",
      { value: Number(nativeView.status) })
  }
  Support.PdfViewBridge { renderer: root.renderer; view: nativeView }
  Component.onCompleted: {
    if (String(renderer.prop("document_source", "")) !== "" && !sharedDocumentItem)
      renderer.componentError("pdf_document_source_missing", "The pdf_document named by document_source was not found",
        { document_source: String(renderer.prop("document_source", "")) })
  }
}
