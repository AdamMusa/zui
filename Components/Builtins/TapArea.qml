import QtQuick
import "Support" as Support

Item {
  id: root
  required property var renderer
  implicitWidth: Number(renderer.prop("width", contentHost.childrenRect.width || 44))
  implicitHeight: Number(renderer.prop("height", contentHost.childrenRect.height || 44))
  visible: renderer.prop("visible", true) !== false

  function policy(value) {
    var name = String(value || "drag_threshold")
    if (name === "release_within_bounds") return TapHandler.ReleaseWithinBounds
    if (name === "within_bounds") return TapHandler.WithinBounds
    return TapHandler.DragThreshold
  }

  function exclusiveSignals(value) {
    var name = String(value || "none")
    if (name === "single_tap") return TapHandler.SingleTap
    if (name === "double_tap") return TapHandler.DoubleTap
    if (name === "both") return TapHandler.SingleTap | TapHandler.DoubleTap
    return TapHandler.NotExclusive
  }

  function payload(button) {
    var resolved = flags.handlerPoint(nativeTap.point)
    resolved.button = Number(button || nativeTap.point.pressedButtons)
    resolved.tap_count = nativeTap.tapCount
    resolved.time_held = nativeTap.timeHeld
    return resolved
  }

  // cursorShape and grabPermissions are only written when the application asks
  // for them: writing them unconditionally would make every tap_area override
  // the cursor and the grab arbitration Qt would otherwise choose.
  function applyOptionalHandlerProperties() {
    if (renderer.hasProp("cursor")) nativeTap.cursorShape = flags.cursorShape(renderer.prop("cursor", null), "arrow")
    if (renderer.hasProp("grab_permissions")) nativeTap.grabPermissions = flags.grabPermissions(renderer.prop("grab_permissions", null), [])
    if (renderer.hasProp("drag_threshold")) nativeTap.dragThreshold = Number(renderer.prop("drag_threshold", 0))
  }

  Support.PointerFlags { id: flags }
  Item { id: contentHost; anchors.fill: parent; Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent } }
  TapHandler {
    id: nativeTap
    enabled: renderer.prop("enabled", true) !== false
    acceptedButtons: flags.buttons(renderer.prop("accepted_buttons", null), ["left"])
    acceptedDevices: flags.devices(renderer.prop("accepted_devices", null), ["all"])
    acceptedPointerTypes: flags.pointerTypes(renderer.prop("accepted_pointer_types", null), ["all"])
    acceptedModifiers: flags.modifiers(renderer.prop("accepted_modifiers", null), ["any"])
    gesturePolicy: root.policy(renderer.prop("gesture_policy", "drag_threshold"))
    exclusiveSignals: root.exclusiveSignals(renderer.prop("exclusive_signals", "none"))
    longPressThreshold: Number(renderer.prop("long_press_threshold", 0.8))
    margin: Number(renderer.prop("margin", 0))
    onTapped: function(point, button) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "tap", root.payload(button)) }
    onSingleTapped: function(point, button) { if (renderer.subscribed("single_tap")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "single_tap", root.payload(button)) }
    onDoubleTapped: function(point, button) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "double_tap", root.payload(button)) }
    onLongPressed: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "long_press", root.payload(0))
    onPressedChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, pressed ? "press" : "release", root.payload(0))
    onCanceled: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "cancel", root.payload(0))
  }

  Component.onCompleted: applyOptionalHandlerProperties()
  Connections { target: renderer; function onNodeChanged() { root.applyOptionalHandlerProperties() } }
}
