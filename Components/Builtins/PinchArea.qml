import QtQuick
import "Support" as Support

Item {
  id: pinchRoot
  property var renderer: null
  implicitWidth: Number(renderer ? renderer.prop("width", contentHost.childrenRect.width) : 200)
  implicitHeight: Number(renderer ? renderer.prop("height", contentHost.childrenRect.height) : 160)

  function applyOptionalHandlerProperties() {
    if (!renderer) return
    if (renderer.hasProp("cursor")) nativePinch.cursorShape = flags.cursorShape(renderer.prop("cursor", null), "arrow")
    if (renderer.hasProp("grab_permissions")) nativePinch.grabPermissions = flags.grabPermissions(renderer.prop("grab_permissions", null), [])
  }

  Support.PointerFlags { id: flags }
  Item { id: contentHost; anchors.fill: parent; Repeater { model: renderer ? (renderer.node.children || []) : []; delegate: renderer.childDelegateComponent } }
  PinchHandler {
    id: nativePinch
    enabled: renderer && renderer.prop("enabled", true) !== false
    target: { var id = renderer ? String(renderer.prop("target", "")) : ""; return id === "" ? contentHost : renderer.findRenderedItem(id) }
    minimumScale: Number(renderer ? renderer.prop("minimum_scale", 0.1) : 0.1); maximumScale: Number(renderer ? renderer.prop("maximum_scale", 10) : 10)
    minimumRotation: Number(renderer ? renderer.prop("minimum_rotation", -Infinity) : -Infinity); maximumRotation: Number(renderer ? renderer.prop("maximum_rotation", Infinity) : Infinity)
    xAxis.minimum: Number(renderer ? renderer.prop("minimum_x", -Infinity) : -Infinity); xAxis.maximum: Number(renderer ? renderer.prop("maximum_x", Infinity) : Infinity)
    yAxis.minimum: Number(renderer ? renderer.prop("minimum_y", -Infinity) : -Infinity); yAxis.maximum: Number(renderer ? renderer.prop("maximum_y", Infinity) : Infinity)
    xAxis.enabled: !renderer || renderer.prop("translate_x", true) !== false
    yAxis.enabled: !renderer || renderer.prop("translate_y", true) !== false
    scaleAxis.enabled: !renderer || renderer.prop("scale_enabled", true) !== false
    rotationAxis.enabled: !renderer || renderer.prop("rotation_enabled", true) !== false
    minimumPointCount: Number(renderer ? renderer.prop("minimum_points", 2) : 2)
    maximumPointCount: Number(renderer ? renderer.prop("maximum_points", 2) : 2)
    acceptedDevices: flags.devices(renderer ? renderer.prop("accepted_devices", null) : null, ["all"])
    acceptedPointerTypes: flags.pointerTypes(renderer ? renderer.prop("accepted_pointer_types", null) : null, ["all"])
    acceptedModifiers: flags.modifiers(renderer ? renderer.prop("accepted_modifiers", null) : null, ["any"])
    margin: Number(renderer ? renderer.prop("margin", 0) : 0)
    function payload() {
      return {
        scale: activeScale, rotation: activeRotation,
        persistent_scale: persistentScale, persistent_rotation: persistentRotation,
        total_scale: nativePinch.scale, total_rotation: nativePinch.rotation,
        translation_x: activeTranslation.x, translation_y: activeTranslation.y,
        persistent_translation_x: persistentTranslation.x, persistent_translation_y: persistentTranslation.y,
        centroid_x: centroid.position.x, centroid_y: centroid.position.y,
        centroid_scene_x: centroid.scenePosition.x, centroid_scene_y: centroid.scenePosition.y
      }
    }
    onActiveChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, active ? "pinch_start" : "pinch_end", payload())
    onActiveScaleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "pinch", payload())
    onActiveRotationChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "pinch", payload())
    onUpdated: { if (renderer.subscribed("update")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "update", payload()) }
    onCanceled: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "cancel", {})
  }

  Component.onCompleted: applyOptionalHandlerProperties()
  Connections { target: renderer; function onNodeChanged() { pinchRoot.applyOptionalHandlerProperties() } }
}
