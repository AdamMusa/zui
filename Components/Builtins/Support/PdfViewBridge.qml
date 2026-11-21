import QtQuick

Item {
  id: root
  required property var renderer
  required property var view
  property int handledCommandRevision: -1
  visible: false

  function send(name, payload) {
    root.renderer.bridge.sendEvent(root.renderer.surfaceName, root.renderer.controlId, name, payload || {})
  }
  function pageCount() { return root.view.document ? Number(root.view.document.pageCount) : 0 }
  function runCommand() {
    var revision = Number(root.renderer.prop("command_revision", 0))
    if (revision === handledCommandRevision) return
    var first = handledCommandRevision < 0
    handledCommandRevision = revision
    if (first) {
      var initial = Number(root.renderer.prop("page", 0))
      if (initial > 0) Qt.callLater(function() { root.view.goToPage(initial) })
      if (revision <= 0) return
    }
    var command = String(root.renderer.prop("command", ""))
    if (command === "") return
    if (command === "next") { root.view.goToPage(Math.min(pageCount() - 1, root.view.currentPage + 1)); return }
    if (command === "previous") { root.view.goToPage(Math.max(0, root.view.currentPage - 1)); return }
    if (command === "page") { root.view.goToPage(Number(root.renderer.prop("page", 0))); return }
    if (command === "back") { root.view.back(); return }
    if (command === "forward") { root.view.forward(); return }
    if (command === "zoom_in") { root.view.renderScale *= 1.2; return }
    if (command === "zoom_out") { root.view.renderScale /= 1.2; return }
    if (command === "reset_zoom") { root.view.resetScale(); return }
    if (command === "scale_to_width") { root.view.scaleToWidth(root.view.width, root.view.height); return }
    if (command === "scale_to_page") { root.view.scaleToPage(root.view.width, root.view.height); return }
    if (command === "select_all") { root.view.selectAll(); return }
    if (command === "copy") { root.view.copySelectionToClipboard(); return }
    if (command === "search_next") { root.view.searchForward(); return }
    if (command === "search_previous") { root.view.searchBack(); return }
    root.renderer.componentError("pdf_command_rejected", "The PDF view does not support the requested command", { command: command })
  }
  Connections {
    target: root.view
    function onCurrentPageChanged() {
      root.send("page_change", { value: Number(root.view.currentPage), page_count: root.pageCount(),
        back_enabled: root.view.backEnabled === true, forward_enabled: root.view.forwardEnabled === true })
    }
    function onSelectedTextChanged() { root.send("selection", { text: String(root.view.selectedText) }) }
    function onSearchStringChanged() {
      root.send("search_change", { value: String(root.view.searchString),
        count: root.view.searchModel ? Number(root.view.searchModel.count) : 0 })
    }
    function onRenderScaleChanged() { root.send("zoom_change", { value: Number(root.view.renderScale) }) }
  }
  Connections { target: root.renderer; function onNodeChanged() { root.runCommand() } }
  Component.onCompleted: runCommand()
}
