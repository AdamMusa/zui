import QtQuick
import QtQuick.Pdf

Item {
  id: root
  required property var renderer
  readonly property alias document: nativeDocument
  property int handledRefreshRevision: -1
  visible: false

  function statusName(value) { return ["null", "loading", "ready", "unloading", "error"][Number(value)] || "unknown" }
  function timestamp(value) { return value && !isNaN(value.getTime()) ? value.toISOString() : "" }
  function send(name, payload) {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }
  function publishMetadata() {
    send("metadata", {
      title: String(nativeDocument.title), subject: String(nativeDocument.subject),
      author: String(nativeDocument.author), keywords: String(nativeDocument.keywords),
      producer: String(nativeDocument.producer), creator: String(nativeDocument.creator),
      creation_date: timestamp(nativeDocument.creationDate),
      modification_date: timestamp(nativeDocument.modificationDate),
      page_count: Number(nativeDocument.pageCount),
      max_page_width: Number(nativeDocument.maxPageWidth),
      max_page_height: Number(nativeDocument.maxPageHeight)
    })
  }
  function publishPages() {
    var pages = []
    for (var index = 0; index < nativeDocument.pageCount; index++) {
      var size = nativeDocument.pagePointSize(index)
      pages.push({ index: index, label: String(nativeDocument.pageLabel(index)),
        width: Number(size.width), height: Number(size.height) })
    }
    send("pages", { pages: pages, count: pages.length })
  }
  function refresh() {
    var revision = Number(renderer.prop("refresh_revision", 0))
    if (revision === handledRefreshRevision) return
    handledRefreshRevision = revision
    publishMetadata()
    if (nativeDocument.status === PdfDocument.Ready) publishPages()
  }

  PdfDocument {
    id: nativeDocument
    source: String(root.renderer.prop("source", ""))
    password: String(root.renderer.prop("password", ""))
    onStatusChanged: function(status) {
      var name = root.statusName(status)
      root.send("status", { value: name, native_status: Number(status), page_count: Number(nativeDocument.pageCount) })
      if (name === "ready") { root.publishMetadata(); root.publishPages() }
      if (name === "error")
        root.renderer.componentError("pdf_load_failed", String(nativeDocument.error), { source: String(nativeDocument.source) })
    }
    onPageCountChanged: function(pageCount) { root.send("page_count", { value: Number(pageCount) }) }
    onMetaDataChanged: root.publishMetadata()
    onPasswordRequired: root.send("password_required", {})
  }
  Connections { target: renderer; function onNodeChanged() { root.refresh() } }
  Component.onCompleted: refresh()
}
