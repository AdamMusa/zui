import QtQuick

Item {
  id: hoverRoot
  property var renderer: null
  function cursorShape(name) { var value=String(name||"pointing_hand");if(value==="arrow")return Qt.ArrowCursor;if(value==="cross")return Qt.CrossCursor;if(value==="text")return Qt.IBeamCursor;if(value==="open_hand")return Qt.OpenHandCursor;if(value==="closed_hand")return Qt.ClosedHandCursor;return Qt.PointingHandCursor }
  implicitWidth: Number(renderer ? renderer.prop("width", contentHost.childrenRect.width) : 120)
  implicitHeight: Number(renderer ? renderer.prop("height", contentHost.childrenRect.height) : 80)
  Item { id: contentHost; anchors.fill: parent; Repeater { model: renderer ? (renderer.node.children || []) : []; delegate: renderer.childDelegateComponent } }
  HoverHandler {
    id: nativeHover
    enabled: renderer && renderer.prop("enabled", true) !== false
    blocking: renderer && renderer.prop("blocking", false) === true
    margin: Number(renderer ? renderer.prop("margin", 0) : 0)
    cursorShape: hoverRoot.cursorShape(renderer ? renderer.prop("cursor", "pointing_hand") : "pointing_hand")
    onHoveredChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, hovered ? "enter" : "exit", { x: point.position.x, y: point.position.y })
    onPointChanged: if (hovered) { var payload = { x: point.position.x, y: point.position.y }; renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "move", payload); renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", payload) }
  }
}
