import QtQuick
import QtQml.Models
import QtQuick.Pdf
import "Support" as Support

Item {
  id: root
  required property var renderer
  readonly property int maximumDepth: 3
  visible: false

  // A PDF outline is a tree, and QML walks a tree model one level at a time through
  // DelegateModel.rootIndex. parent_path names the branch to list, as the row indices to
  // follow from the top; the children of a listed row are read by appending that row's
  // index to parent_path. One DelegateModel per level is rooted at the step above it, and
  // each is attached to a Repeater so modelIndex() has materialised rows to resolve
  // against and the level below re-evaluates by itself as the outline loads.
  function path() {
    var value = renderer.prop("parent_path", []) || []
    if (!Array.isArray(value)) value = [value]
    return value
  }
  function pathStep(depth) {
    var value = path()
    return depth < value.length ? Number(value[depth]) : -1
  }
  function rowsForDepth() {
    var depth = Math.min(path().length, maximumDepth)
    if (depth === 0) return depth0Rows
    if (depth === 1) return depth1Rows
    if (depth === 2) return depth2Rows
    return depth3Rows
  }
  function publish() {
    var rows = rowsForDepth()
    var bookmarks = []
    for (var index = 0; index < rows.count; index++) {
      var row = rows.itemAt(index)
      if (!row) continue
      bookmarks.push({ index: index, title: String(row.title), level: Number(row.level),
        page: Number(row.page), zoom: Number(row.zoom),
        x: Number(row.location.x), y: Number(row.location.y) })
    }
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "bookmarks", {
      bookmarks: bookmarks, count: bookmarks.length, parent_path: path()
    })
    if (path().length > maximumDepth)
      renderer.componentError("pdf_bookmark_depth_exceeded", "The outline branch is deeper than this component can walk",
        { requested_depth: path().length, maximum_depth: maximumDepth })
  }

  Support.PdfDocumentSource { id: documentSource; renderer: root.renderer }
  PdfBookmarkModel { id: nativeModel; document: documentSource.document }

  component OutlineRow: Item {
    required property string title
    required property int level
    required property int page
    required property point location
    required property real zoom
  }

  DelegateModel { id: depth0; model: nativeModel; delegate: OutlineRow {} }
  Repeater { id: depth0Rows; model: depth0; onCountChanged: publishTimer.restart() }

  DelegateModel {
    id: depth1
    model: nativeModel
    rootIndex: root.pathStep(0) >= 0 && depth0Rows.count > root.pathStep(0)
      ? depth0.modelIndex(root.pathStep(0)) : undefined
    delegate: OutlineRow {}
  }
  Repeater { id: depth1Rows; model: depth1; onCountChanged: publishTimer.restart() }

  DelegateModel {
    id: depth2
    model: nativeModel
    rootIndex: root.pathStep(1) >= 0 && depth1Rows.count > root.pathStep(1)
      ? depth1.modelIndex(root.pathStep(1)) : undefined
    delegate: OutlineRow {}
  }
  Repeater { id: depth2Rows; model: depth2; onCountChanged: publishTimer.restart() }

  DelegateModel {
    id: depth3
    model: nativeModel
    rootIndex: root.pathStep(2) >= 0 && depth2Rows.count > root.pathStep(2)
      ? depth2.modelIndex(root.pathStep(2)) : undefined
    delegate: OutlineRow {}
  }
  Repeater { id: depth3Rows; model: depth3; onCountChanged: publishTimer.restart() }

  // Rows arrive one delegate at a time, so coalesce them into a single event.
  Timer { id: publishTimer; interval: 16; repeat: false; onTriggered: root.publish() }
  Connections { target: root.renderer; function onNodeChanged() { publishTimer.restart() } }
  Component.onCompleted: publishTimer.restart()
}
