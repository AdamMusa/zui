import QtQuick

Item {
  id: root
  required property var renderer
  implicitWidth: Number(renderer.prop("width", contentHost.childrenRect.width || 44))
  implicitHeight: Number(renderer.prop("height", contentHost.childrenRect.height || 44))
  visible: renderer.prop("visible", true) !== false
  function buttons(value) { var values=Array.isArray(value)?value:[value||"all"];var result=Qt.NoButton;for(var index=0;index<values.length;index++){var name=String(values[index]);if(name==="left")result|=Qt.LeftButton;else if(name==="right")result|=Qt.RightButton;else if(name==="middle")result|=Qt.MiddleButton;else if(name==="all")result|=Qt.AllButtons}return result }
  function devices(value) { var values=Array.isArray(value)?value:[value||"all"];var result=PointerDevice.Unknown;for(var index=0;index<values.length;index++){var name=String(values[index]);if(name==="mouse")result|=PointerDevice.Mouse;else if(name==="touch_screen")result|=PointerDevice.TouchScreen;else if(name==="touch_pad")result|=PointerDevice.TouchPad;else if(name==="stylus")result|=PointerDevice.Stylus;else if(name==="all")result|=PointerDevice.AllDevices}return result }
  function payload() { return { x: nativePoint.point.position.x, y: nativePoint.point.position.y, scene_x: nativePoint.point.scenePosition.x, scene_y: nativePoint.point.scenePosition.y, pressure: nativePoint.point.pressure, rotation: nativePoint.point.rotation, unique_id: String(nativePoint.point.uniqueId.numericId) } }
  Item { id: contentHost; anchors.fill: parent; Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent } }
  PointHandler {
    id: nativePoint
    enabled: renderer.prop("enabled", true) !== false
    acceptedButtons: root.buttons(renderer.prop("accepted_buttons", ["all"]))
    acceptedDevices: root.devices(renderer.prop("accepted_devices", ["all"]))
    margin: Number(renderer.prop("margin", 0))
    onPointChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "point", root.payload())
    onActiveChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "active_change", { value: active })
    onCanceled: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "cancel", root.payload())
  }
}
