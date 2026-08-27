import QtQuick

Item {
  id: root
  required property var renderer
  implicitWidth: Number(renderer.prop("width", contentHost.childrenRect.width || 44))
  implicitHeight: Number(renderer.prop("height", contentHost.childrenRect.height || 44))
  visible: renderer.prop("visible", true) !== false
  function buttons(value) {
    var values=Array.isArray(value)?value:[value||"left"];var result=Qt.NoButton
    for(var index=0;index<values.length;index++){var name=String(values[index]);if(name==="left")result|=Qt.LeftButton;else if(name==="right")result|=Qt.RightButton;else if(name==="middle")result|=Qt.MiddleButton;else if(name==="all")result|=Qt.AllButtons}
    return result
  }
  function policy(value) {
    var name=String(value||"drag_threshold");if(name==="release_within_bounds")return TapHandler.ReleaseWithinBounds;if(name==="within_bounds")return TapHandler.WithinBounds;return TapHandler.DragThreshold
  }
  function payload(button) { return { x: nativeTap.point.position.x, y: nativeTap.point.position.y, pressure: nativeTap.point.pressure, button: Number(button||nativeTap.point.pressedButtons) } }
  Item { id: contentHost; anchors.fill: parent; Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent } }
  TapHandler {
    id: nativeTap
    enabled: renderer.prop("enabled", true) !== false
    acceptedButtons: root.buttons(renderer.prop("accepted_buttons", ["left"]))
    gesturePolicy: root.policy(renderer.prop("gesture_policy", "drag_threshold"))
    longPressThreshold: Number(renderer.prop("long_press_threshold", 0.8))
    onTapped: function(point, button) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "tap", root.payload(button)) }
    onDoubleTapped: function(point, button) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "double_tap", root.payload(button)) }
    onLongPressed: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "long_press", root.payload(0))
    onPressedChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, pressed ? "press" : "release", root.payload(0))
    onCanceled: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "cancel", root.payload(0))
  }
}
