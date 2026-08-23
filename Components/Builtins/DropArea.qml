import QtQuick

Item {
  id: dropRoot
  property var renderer: null
  implicitWidth: Number(renderer ? renderer.prop("width", contentHost.childrenRect.width) : 160)
  implicitHeight: Number(renderer ? renderer.prop("height", contentHost.childrenRect.height) : 100)
  Item { id: contentHost; anchors.fill: parent; Repeater { model: renderer ? (renderer.node.children || []) : []; delegate: renderer.childDelegateComponent } }
  DropArea {
    anchors.fill: parent
    enabled: renderer && renderer.prop("enabled", true) !== false
    keys: renderer ? renderer.prop("keys", []) : []
    function payload(drag) { return { x: drag.x, y: drag.y, keys: drag.keys, formats: drag.formats, text: drag.hasText ? drag.text : null, urls: drag.hasUrls ? drag.urls.map(String) : [] } }
    onEntered: function(drag) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "enter", payload(drag)) }
    onPositionChanged: function(drag) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "move", payload(drag)) }
    onExited: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "exit", {})
    onDropped: function(drop) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "drop", payload(drop)); drop.acceptProposedAction() }
  }
}
