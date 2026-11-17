import QtQuick
import QtQuick.Pdf
import "Support" as Support

Item {
  id: root
  required property var renderer
  visible: false

  function send(name, payload) {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }
  function publishResults() {
    var results = []
    for (var index = 0; index < resultRows.count; index++) {
      var row = resultRows.itemAt(index)
      if (!row) continue
      results.push({ index: index, page: Number(row.page), index_on_page: Number(row.indexOnPage),
        x: Number(row.location.x), y: Number(row.location.y),
        context_before: String(row.contextBefore), context_after: String(row.contextAfter) })
    }
    send("results", { results: results, count: Number(nativeModel.count) })
    send("count", { value: Number(nativeModel.count) })
  }
  function linkPayload(link) {
    if (!link) return { valid: false }
    return { valid: link.valid === true, page: Number(link.page), zoom: Number(link.zoom),
      url: String(link.url), x: Number(link.location.x), y: Number(link.location.y),
      context_before: String(link.contextBefore), context_after: String(link.contextAfter) }
  }
  function publishCurrent() {
    var rect = nativeModel.currentResultBoundingRect
    send("current_result", {
      index: Number(nativeModel.currentResult), page: Number(nativeModel.currentPage),
      link: linkPayload(nativeModel.currentResultLink),
      bounding_rect: { x: Number(rect.x), y: Number(rect.y), width: Number(rect.width), height: Number(rect.height) },
      page_polygon_points: nativeModel.currentPageBoundingPolygons.length,
      result_polygon_points: nativeModel.currentResultBoundingPolygons.length
    })
  }

  Support.PdfDocumentSource { id: documentSource; renderer: root.renderer }
  PdfSearchModel {
    id: nativeModel
    document: documentSource.document
    searchString: String(root.renderer.prop("search", ""))
    currentPage: Number(root.renderer.prop("current_page", 0))
    currentResult: Number(root.renderer.prop("current_result", 0))
    onCurrentResultChanged: root.publishCurrent()
    onCurrentResultLinkChanged: root.publishCurrent()
  }
  // PdfSearchModel is a list model, so its rows are read the way QML reads any model: a
  // Repeater holds one item per result and the payload is built from those items, which
  // keeps the published set exactly in step with the model instead of accumulating.
  Repeater {
    id: resultRows
    model: nativeModel
    delegate: Item {
      required property int page
      required property int indexOnPage
      required property point location
      required property string contextBefore
      required property string contextAfter
    }
    onCountChanged: publishTimer.restart()
  }
  // Rows arrive one delegate at a time, so coalesce them into a single event.
  Timer { id: publishTimer; interval: 16; repeat: false; onTriggered: root.publishResults() }
  Connections { target: root.renderer; function onNodeChanged() { publishTimer.restart() } }
  Component.onCompleted: publishTimer.restart()
}
