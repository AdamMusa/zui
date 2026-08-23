import QtQuick

Item {
  id: pinchRoot
  property var renderer: null
  implicitWidth: Number(renderer ? renderer.prop("width", contentHost.childrenRect.width) : 200)
  implicitHeight: Number(renderer ? renderer.prop("height", contentHost.childrenRect.height) : 160)
  Item { id: contentHost; anchors.fill: parent; Repeater { model: renderer ? (renderer.node.children || []) : []; delegate: renderer.childDelegateComponent } }
  PinchHandler {
    id: nativePinch
    enabled: renderer && renderer.prop("enabled", true) !== false
    target: { var id = renderer ? String(renderer.prop("target", "")) : ""; return id === "" ? contentHost : renderer.findRenderedItem(id) }
    minimumScale: Number(renderer ? renderer.prop("minimum_scale", 0.1) : 0.1); maximumScale: Number(renderer ? renderer.prop("maximum_scale", 10) : 10)
    minimumRotation: Number(renderer ? renderer.prop("minimum_rotation", -Infinity) : -Infinity); maximumRotation: Number(renderer ? renderer.prop("maximum_rotation", Infinity) : Infinity)
    xAxis.minimum: Number(renderer ? renderer.prop("minimum_x", -Infinity) : -Infinity); xAxis.maximum: Number(renderer ? renderer.prop("maximum_x", Infinity) : Infinity)
    yAxis.minimum: Number(renderer ? renderer.prop("minimum_y", -Infinity) : -Infinity); yAxis.maximum: Number(renderer ? renderer.prop("maximum_y", Infinity) : Infinity)
    function payload() { return { scale: activeScale, rotation: activeRotation, translation_x: activeTranslation.x, translation_y: activeTranslation.y, centroid_x: centroid.position.x, centroid_y: centroid.position.y } }
    onActiveChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, active ? "pinch_start" : "pinch_end", payload())
    onActiveScaleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "pinch", payload())
    onActiveRotationChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "pinch", payload())
    onCanceled: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "cancel", {})
  }
}
