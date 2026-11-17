import QtQuick
import QtQuick.Pdf
import "Support" as Support

Item {
  id: root
  required property var renderer
  // document_source names a pdf_document component whose document this view renders; without
  // one the view owns a document built from its own source and password.
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
    onStatusChanged: function(status) {
      if (status === PdfDocument.Error)
        root.renderer.componentError("pdf_load_failed", String(ownDocument.error), { source: String(ownDocument.source) })
    }
  }
  PdfMultiPageView {
    id: nativeView
    anchors.fill: parent
    document: root.activeDocument
    renderScale: Number(root.renderer.prop("zoom", 1))
    pageRotation: Number(root.renderer.prop("rotation", 0))
    searchString: String(root.renderer.prop("search", ""))
  }
  Support.PdfViewBridge { renderer: root.renderer; view: nativeView }
  Component.onCompleted: {
    if (String(renderer.prop("document_source", "")) !== "" && !sharedDocumentItem)
      renderer.componentError("pdf_document_source_missing", "The pdf_document named by document_source was not found",
        { document_source: String(renderer.prop("document_source", "")) })
  }
}
