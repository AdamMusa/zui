import QtQuick

Item {
  id: hoverRoot
  property var renderer: null
  implicitWidth: Number(renderer ? renderer.prop("width", contentHost.childrenRect.width) : 120)
  implicitHeight: Number(renderer ? renderer.prop("height", contentHost.childrenRect.height) : 80)
  Item { id: contentHost; anchors.fill: parent; Repeater { model: renderer ? (renderer.node.children || []) : []; delegate: renderer.childDelegateComponent } }
  HoverHandler {
    id: nativeHover
    enabled: renderer && renderer.prop("enabled", true) !== false
    blocking: renderer && renderer.prop("blocking", false) === true
    margin: Number(renderer ? renderer.prop("margin", 0) : 0)
    cursorShape: renderer ? renderer.cursorShape(renderer.prop("cursor", "pointing_hand"))
      : Qt.PointingHandCursor
    onHoveredChanged: if (renderer && renderer.bridge) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, hovered ? "enter" : "exit", { x: point.position.x, y: point.position.y })
    onPointChanged: if (hovered) { var payload = { x: point.position.x, y: point.position.y }; renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "move", payload); renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", payload) }
  }
}
