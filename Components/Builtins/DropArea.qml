import QtQuick

Item {
  id: dropRoot
  property var renderer: null
  implicitWidth: Number(renderer ? renderer.prop("width", contentHost.childrenRect.width) : 160)
  implicitHeight: Number(renderer ? renderer.prop("height", contentHost.childrenRect.height) : 100)
  Item { id: contentHost; anchors.fill: parent; Repeater { model: renderer ? (renderer.node.children || []) : []; delegate: renderer.childDelegateComponent } }
  DropArea {
    id: nativeDrop
    anchors.fill: parent
    enabled: renderer && renderer.prop("enabled", true) !== false
    keys: renderer ? renderer.prop("keys", []) : []

    function action(name) {
      var requested = String(name || "")
      if (requested === "copy") return Qt.CopyAction
      if (requested === "move") return Qt.MoveAction
      if (requested === "link") return Qt.LinkAction
      if (requested === "ignore") return Qt.IgnoreAction
      return -1
    }

    function payload(drag) {
      return {
        x: drag.x, y: drag.y, keys: drag.keys, formats: drag.formats,
        text: drag.hasText ? drag.text : null,
        html: drag.hasHtml ? drag.html : null,
        color: drag.hasColor ? String(drag.colorData) : null,
        urls: drag.hasUrls ? drag.urls.map(String) : [],
        proposed_action: Number(drag.proposedAction),
        supported_actions: Number(drag.supportedActions),
        has_source: !!drag.source
      }
    }

    onEntered: function(drag) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "enter", payload(drag)) }
    onPositionChanged: function(drag) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "move", payload(drag)) }
    onExited: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "exit", {})
    onDropped: function(drop) {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "drop", payload(drop))
      if (renderer.prop("accept", true) === false) return
      var requested = action(renderer.prop("action", ""))
      if (requested < 0) drop.acceptProposedAction()
      else drop.accept(requested)
    }
    onContainsDragChanged: {
      if (renderer.subscribed("contains_change"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "contains_change", {
          value: containsDrag,
          x: nativeDrop.drag.x, y: nativeDrop.drag.y
        })
    }
  }
}
