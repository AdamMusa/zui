import QtQuick
import QtQuick.Pdf

// Resolves the PdfDocument a PDF model works on: either the one owned by the pdf_document
// component named by document_source, or a private one built from source and password.
Item {
  id: root
  required property var renderer
  readonly property var sharedItem: {
    var name = String(root.renderer.prop("document_source", ""))
    return name === "" ? null : root.renderer.findRenderedItem(name)
  }
  readonly property var document: sharedItem && sharedItem.document !== undefined ? sharedItem.document : ownDocument
  visible: false

  PdfDocument {
    id: ownDocument
    source: root.sharedItem ? "" : String(root.renderer.prop("source", ""))
    password: String(root.renderer.prop("password", ""))
    onStatusChanged: function(status) {
      if (status === PdfDocument.Error)
        root.renderer.componentError("pdf_load_failed", String(ownDocument.error), { source: String(ownDocument.source) })
    }
  }
  Component.onCompleted: {
    if (String(root.renderer.prop("document_source", "")) !== "" && !sharedItem)
      root.renderer.componentError("pdf_document_source_missing", "The pdf_document named by document_source was not found",
        { document_source: String(root.renderer.prop("document_source", "")) })
  }
}
