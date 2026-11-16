import QtQuick
import "Support" as Support

Item {
  id: root
  required property var renderer
  implicitWidth: Number(renderer.prop("width", contentHost.childrenRect.width || 44))
  implicitHeight: Number(renderer.prop("height", contentHost.childrenRect.height || 44))
  visible: renderer.prop("visible", true) !== false

  function wheelTarget() {
    var identifier = String(renderer.prop("target", ""))
    return identifier === "" ? null : renderer.findRenderedItem(identifier)
  }

  // target_property turns the handler into Qt's value-adjusting mode, and
  // cursorShape / grabPermissions override Qt's arbitration, so all three are
  // written only when the application asks for them.
  function applyOptionalHandlerProperties() {
    if (renderer.hasProp("target_property")) nativeWheel.property = String(renderer.prop("target_property", ""))
    if (renderer.hasProp("cursor")) nativeWheel.cursorShape = flags.cursorShape(renderer.prop("cursor", null), "arrow")
    if (renderer.hasProp("grab_permissions")) nativeWheel.grabPermissions = flags.grabPermissions(renderer.prop("grab_permissions", null), [])
  }

  Support.PointerFlags { id: flags }
  Item { id: contentHost; anchors.fill: parent; Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent } }
  WheelHandler {
    id: nativeWheel
    enabled: renderer.prop("enabled", true) !== false
    blocking: renderer.prop("blocking", true) !== false
    acceptedDevices: flags.devices(renderer.prop("accepted_devices", null), ["mouse", "touch_pad"])
    acceptedPointerTypes: flags.pointerTypes(renderer.prop("accepted_pointer_types", null), ["all"])
    acceptedModifiers: flags.modifiers(renderer.prop("accepted_modifiers", null), ["any"])
    orientation: String(renderer.prop("orientation", "vertical")) === "horizontal" ? Qt.Horizontal : Qt.Vertical
    invertible: renderer.prop("invertible", true) !== false
    activeTimeout: Number(renderer.prop("active_timeout", 0.1))
    rotationScale: Number(renderer.prop("rotation_scale", 1))
    targetScaleMultiplier: Number(renderer.prop("target_scale_multiplier", Math.pow(2, 1 / 3)))
    targetTransformAroundCursor: renderer.prop("target_transform_around_cursor", true) !== false
    margin: Number(renderer.prop("margin", 0))
    target: root.wheelTarget()
    onWheel: function(event) {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "wheel", {
        angle_x: event.angleDelta.x, angle_y: event.angleDelta.y,
        pixel_x: event.pixelDelta.x, pixel_y: event.pixelDelta.y,
        x: event.position.x, y: event.position.y,
        modifiers: Number(event.modifiers), buttons: Number(event.buttons),
        inverted: event.inverted === true, phase: Number(event.phase),
        rotation: nativeWheel.rotation
      })
    }
    onActiveChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "active_change", { value: active })
    onRotationChanged: {
      if (renderer.subscribed("rotation_change"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "rotation_change", { value: nativeWheel.rotation })
    }
  }

  Component.onCompleted: applyOptionalHandlerProperties()
  Connections { target: renderer; function onNodeChanged() { root.applyOptionalHandlerProperties() } }
}
