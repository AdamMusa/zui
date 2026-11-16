import QtQuick
import "Support" as Support

Item {
  id: hoverRoot
  property var renderer: null
  implicitWidth: Number(renderer ? renderer.prop("width", contentHost.childrenRect.width) : 120)
  implicitHeight: Number(renderer ? renderer.prop("height", contentHost.childrenRect.height) : 80)

  // grabPermissions keeps Qt's own default unless the application asks for
  // something else, so binding it cannot silently change grab arbitration.
  function applyGrabPermissions() {
    if (!renderer || !renderer.hasProp("grab_permissions")) return
    nativeHover.grabPermissions = flags.grabPermissions(renderer.prop("grab_permissions", null), [])
  }

  Support.PointerFlags { id: flags }
  Item { id: contentHost; anchors.fill: parent; Repeater { model: renderer ? (renderer.node.children || []) : []; delegate: renderer.childDelegateComponent } }
  HoverHandler {
    id: nativeHover
    enabled: renderer && renderer.prop("enabled", true) !== false
    blocking: renderer && renderer.prop("blocking", false) === true
    margin: Number(renderer ? renderer.prop("margin", 0) : 0)
    cursorShape: flags.cursorShape(renderer ? renderer.prop("cursor", null) : null, "pointing_hand")
    acceptedDevices: flags.devices(renderer ? renderer.prop("accepted_devices", null) : null, ["all"])
    acceptedPointerTypes: flags.pointerTypes(renderer ? renderer.prop("accepted_pointer_types", null) : null, ["all"])
    acceptedModifiers: flags.modifiers(renderer ? renderer.prop("accepted_modifiers", null) : null, ["any"])
    onHoveredChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, hovered ? "enter" : "exit", flags.handlerPoint(point))
    onPointChanged: if (hovered) { var payload = flags.handlerPoint(point); renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "move", payload); renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", payload) }
  }

  Component.onCompleted: applyGrabPermissions()
  Connections { target: renderer; function onNodeChanged() { hoverRoot.applyGrabPermissions() } }
}
