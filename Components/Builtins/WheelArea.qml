import QtQuick

Item {
  id: root
  required property var renderer
  implicitWidth: Number(renderer.prop("width", contentHost.childrenRect.width || 44))
  implicitHeight: Number(renderer.prop("height", contentHost.childrenRect.height || 44))
  visible: renderer.prop("visible", true) !== false
  function devices(value) { var values=Array.isArray(value)?value:[value||"mouse"];var result=PointerDevice.Unknown;for(var index=0;index<values.length;index++){var name=String(values[index]);if(name==="mouse")result|=PointerDevice.Mouse;else if(name==="touch_screen")result|=PointerDevice.TouchScreen;else if(name==="touch_pad")result|=PointerDevice.TouchPad;else if(name==="stylus")result|=PointerDevice.Stylus;else if(name==="all")result|=PointerDevice.AllDevices}return result }
  Item { id: contentHost; anchors.fill: parent; Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent } }
  WheelHandler {
    id: nativeWheel
    enabled: renderer.prop("enabled", true) !== false
    blocking: renderer.prop("blocking", true) !== false
    acceptedDevices: root.devices(renderer.prop("accepted_devices", ["mouse", "touch_pad"]))
    onWheel: function(event) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "wheel", { angle_x: event.angleDelta.x, angle_y: event.angleDelta.y, pixel_x: event.pixelDelta.x, pixel_y: event.pixelDelta.y, x: event.position.x, y: event.position.y, modifiers: Number(event.modifiers) }) }
    onActiveChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "active_change", { value: active })
  }
}
