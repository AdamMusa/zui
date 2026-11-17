import QtQuick
import QtQuick.Pdf
import "Support" as Support

Item {
  id: root
  required property var renderer
  visible: false

  function publish() {
    var links = []
    for (var index = 0; index < linkRows.count; index++) {
      var row = linkRows.itemAt(index)
      if (!row) continue
      links.push({ index: index, url: String(row.url), page: Number(row.page),
        zoom: Number(row.zoom), x: Number(row.location.x), y: Number(row.location.y),
        rectangle: { x: Number(row.rectangle.x), y: Number(row.rectangle.y),
          width: Number(row.rectangle.width), height: Number(row.rectangle.height) },
        internal: Number(row.page) >= 0 })
    }
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "links",
      { links: links, count: links.length, page: Number(nativeModel.page) })
  }

  Support.PdfDocumentSource { id: documentSource; renderer: root.renderer }
  // QPdfLinkModel reports a web link with page -1 and its url set, and an internal
  // destination with a page index and no url, so the payload marks which kind each is.
  PdfLinkModel {
    id: nativeModel
    document: documentSource.document
    page: Number(root.renderer.prop("page", 0))
  }
  Repeater {
    id: linkRows
    model: nativeModel
    delegate: Item {
      required property rect rectangle
      required property url url
      required property int page
      required property point location
      required property real zoom
    }
    onCountChanged: publishTimer.restart()
  }
  // Rows arrive one delegate at a time, so coalesce them into a single event.
  Timer { id: publishTimer; interval: 16; repeat: false; onTriggered: root.publish() }
  Connections { target: root.renderer; function onNodeChanged() { publishTimer.restart() } }
  Component.onCompleted: publishTimer.restart()
}
