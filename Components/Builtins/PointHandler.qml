import QtQuick
import "Support" as Support

Item {
  id: root
  required property var renderer
  implicitWidth: Number(renderer.prop("width", contentHost.childrenRect.width || 44))
  implicitHeight: Number(renderer.prop("height", contentHost.childrenRect.height || 44))
  visible: renderer.prop("visible", true) !== false

  function payload() {
    var resolved = flags.handlerPoint(nativePoint.point)
    resolved.unique_id = String(nativePoint.point.uniqueId.numericId)
    resolved.translation_x = nativePoint.translation.x
    resolved.translation_y = nativePoint.translation.y
    resolved.active = nativePoint.active
    return resolved
  }

  function applyOptionalHandlerProperties() {
    if (renderer.hasProp("cursor")) nativePoint.cursorShape = flags.cursorShape(renderer.prop("cursor", null), "arrow")
    if (renderer.hasProp("grab_permissions")) nativePoint.grabPermissions = flags.grabPermissions(renderer.prop("grab_permissions", null), [])
    if (renderer.hasProp("drag_threshold")) nativePoint.dragThreshold = Number(renderer.prop("drag_threshold", 0))
  }

  Support.PointerFlags { id: flags }
  Item { id: contentHost; anchors.fill: parent; Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent } }
  PointHandler {
    id: nativePoint
    enabled: renderer.prop("enabled", true) !== false
    acceptedButtons: flags.buttons(renderer.prop("accepted_buttons", null), ["all"])
    acceptedDevices: flags.devices(renderer.prop("accepted_devices", null), ["all"])
    acceptedPointerTypes: flags.pointerTypes(renderer.prop("accepted_pointer_types", null), ["all"])
    acceptedModifiers: flags.modifiers(renderer.prop("accepted_modifiers", null), ["any"])
    margin: Number(renderer.prop("margin", 0))
    onPointChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "point", root.payload())
    onActiveChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "active_change", { value: active })
    onCanceled: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "cancel", root.payload())
  }

  Component.onCompleted: applyOptionalHandlerProperties()
  Connections { target: renderer; function onNodeChanged() { root.applyOptionalHandlerProperties() } }
}
