import QtQuick

MultiPointTouchArea {
  id: root
  required property var renderer
  property var trackedPoints: []
  implicitWidth: Number(renderer.prop("width", contentHost.childrenRect.width || 88))
  implicitHeight: Number(renderer.prop("height", contentHost.childrenRect.height || 88))
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false
  minimumTouchPoints: Number(renderer.prop("minimum_touch_points", 1))
  maximumTouchPoints: Math.max(minimumTouchPoints, Number(renderer.prop("maximum_touch_points", 10)))
  mouseEnabled: renderer.prop("mouse_enabled", false) === true

  function payload(points) {
    var result = []
    for (var index = 0; index < points.length; index++) {
      var point = points[index]
      result.push({ id: point.pointId, x: point.x, y: point.y, scene_x: point.sceneX, scene_y: point.sceneY,
        start_x: point.startX, start_y: point.startY, previous_x: point.previousX, previous_y: point.previousY,
        velocity_x: point.velocity.x, velocity_y: point.velocity.y,
        pressure: point.pressure, rotation: point.rotation,
        ellipse_width: point.ellipseDiameters.width, ellipse_height: point.ellipseDiameters.height,
        pressed: point.pressed })
    }
    return { points: result, count: result.length }
  }

  // The tracked TouchPoint objects are built to match maximum_touch_points so a
  // request for more than ten points is honoured instead of silently clamped.
  function rebuildTouchPoints() {
    var requested = Math.max(1, Number(renderer.prop("maximum_touch_points", 10)))
    if (requested === trackedPoints.length) return
    root.touchPoints = []
    for (var existing = 0; existing < trackedPoints.length; existing++) trackedPoints[existing].destroy()
    var created = []
    for (var index = 0; index < requested; index++) created.push(touchPointFactory.createObject(root))
    trackedPoints = created
    root.touchPoints = created
  }

  Component { id: touchPointFactory; TouchPoint {} }
  Item { id: contentHost; anchors.fill: parent; Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent } }

  onPressed: function(points) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "press", payload(points)) }
  onUpdated: function(points) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "update", payload(points)) }
  onReleased: function(points) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "release", payload(points)) }
  onCanceled: function(points) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "cancel", payload(points)) }
  onGestureStarted: function(gesture) { gesture.grab();renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "gesture", {}) }
  onTouchUpdated: function(points) {
    if (renderer.subscribed("touch_updated"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "touch_updated", payload(points))
  }

  Component.onCompleted: rebuildTouchPoints()
  Connections { target: renderer; function onNodeChanged() { root.rebuildTouchPoints() } }
}
