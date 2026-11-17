import QtQuick

MultiPointTouchArea {
  id: root
  required property var renderer
  implicitWidth: Number(renderer.prop("width", contentHost.childrenRect.width || 88))
  implicitHeight: Number(renderer.prop("height", contentHost.childrenRect.height || 88))
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false
  minimumTouchPoints: Number(renderer.prop("minimum_touch_points", 1))
  maximumTouchPoints: Math.max(minimumTouchPoints, Math.min(10, Number(renderer.prop("maximum_touch_points", 10))))
  mouseEnabled: renderer.prop("mouse_enabled", false) === true
  function payload(points) {
    var result=[];for(var index=0;index<points.length;index++){var point=points[index];result.push({id:point.pointId,x:point.x,y:point.y,scene_x:point.sceneX,scene_y:point.sceneY,pressure:point.pressure,pressed:point.pressed})}return {points:result}
  }
  Item { id: contentHost; anchors.fill: parent; Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent } }
  touchPoints: [TouchPoint{},TouchPoint{},TouchPoint{},TouchPoint{},TouchPoint{},TouchPoint{},TouchPoint{},TouchPoint{},TouchPoint{},TouchPoint{}]
  onPressed: function(points) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "press", payload(points)) }
  onUpdated: function(points) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "update", payload(points)) }
  onReleased: function(points) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "release", payload(points)) }
  onCanceled: function(points) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "cancel", payload(points)) }
  onGestureStarted: function(gesture) { gesture.grab();renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "gesture", {}) }
}
