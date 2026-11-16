import QtQuick
import QtQuick.Pdf

Item {
  id: root
  required property var renderer
  readonly property var sharedDocumentItem: {
    var source = String(renderer.prop("document_source", ""))
    return source === "" ? null : renderer.findRenderedItem(source)
  }
  readonly property var activeDocument: sharedDocumentItem && sharedDocumentItem.document !== undefined
    ? sharedDocumentItem.document : ownDocument
  implicitWidth: Number(renderer.prop("width", 320))
  implicitHeight: Number(renderer.prop("height", 440))
  visible: renderer.prop("visible", true) !== false

  function statusName(value) { return ["null", "ready", "loading", "error"][Number(value)] || "unknown" }
  function fillMode() {
    var value = String(root.renderer.prop("fill_mode", "preserve_aspect_fit"))
    if (value === "stretch") return Image.Stretch
    if (value === "preserve_aspect_crop") return Image.PreserveAspectCrop
    if (value === "pad") return Image.Pad
    return Image.PreserveAspectFit
  }

  PdfDocument {
    id: ownDocument
    source: root.sharedDocumentItem ? "" : String(root.renderer.prop("source", ""))
    password: String(root.renderer.prop("password", ""))
    onStatusChanged: function(status) {
      if (status === PdfDocument.Error)
        root.renderer.componentError("pdf_load_failed", String(ownDocument.error), { source: String(ownDocument.source) })
    }
  }
  // PdfPageImage derives from Image: the page is selected through currentFrame and the
  // rendered resolution through sourceSize, which is how Qt renders one page as an image.
  PdfPageImage {
    id: nativeImage
    anchors.fill: parent
    document: root.activeDocument
    currentFrame: Number(root.renderer.prop("page", 0))
    sourceSize.width: Number(root.renderer.prop("source_width", 0))
    sourceSize.height: Number(root.renderer.prop("source_height", 0))
    fillMode: root.fillMode()
    asynchronous: root.renderer.prop("asynchronous", true) !== false
    mipmap: root.renderer.prop("mipmap", false) === true
    smooth: root.renderer.prop("smooth", true) !== false
    onStatusChanged: function(status) {
      root.renderer.bridge.sendEvent(root.renderer.surfaceName, root.renderer.controlId, "status",
        { value: root.statusName(status), native_status: Number(status), frame_count: Number(nativeImage.frameCount) })
      if (status === Image.Error)
        root.renderer.componentError("pdf_page_render_failed", "The PDF page could not be rendered",
          { page: Number(nativeImage.currentFrame) })
    }
    onProgressChanged: root.renderer.bridge.sendEvent(root.renderer.surfaceName, root.renderer.controlId, "progress", { value: Number(nativeImage.progress) })
    onFrameCountChanged: root.renderer.bridge.sendEvent(root.renderer.surfaceName, root.renderer.controlId, "page_count", { value: Number(nativeImage.frameCount) })
  }
}
