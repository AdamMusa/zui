import QtQuick
import "Support" as Support

Item {
  id: dragRoot
  property var renderer: null
  implicitWidth: Number(renderer ? renderer.prop("width", contentHost.childrenRect.width) : 120)
  implicitHeight: Number(renderer ? renderer.prop("height", contentHost.childrenRect.height) : 80)
  property int resetRevision: Number(renderer ? renderer.prop("reset_revision", 0) : 0)
  onResetRevisionChanged: {
    var item = nativeDrag.target
    if (item) { item.x = 0; item.y = 0 }
  }

  function snapMode(value) {
    var name = String(value || "if_pressed_outside_target")
    if (name === "never") return DragHandler.NoSnap
    if (name === "always") return DragHandler.SnapAlways
    if (name === "auto") return DragHandler.SnapAuto
    return DragHandler.SnapIfPressedOutsideTarget
  }

  function applyOptionalHandlerProperties() {
    if (!renderer) return
    if (renderer.hasProp("grab_permissions")) nativeDrag.grabPermissions = flags.grabPermissions(renderer.prop("grab_permissions", null), [])
  }

  Support.PointerFlags { id: flags }
  Item { id: contentHost; anchors.fill: parent; Repeater { model: renderer ? (renderer.node.children || []) : []; delegate: renderer.childDelegateComponent } }
  TapHandler {
    id: nativeTap
    enabled: renderer && renderer.prop("enabled", true) !== false
    onTapped: function(point, button) {
      if (renderer.subscribed("click")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", { x: point.position.x, y: point.position.y, button: button })
    }
    onDoubleTapped: function(point, button) {
      if (renderer.subscribed("double_click")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "double_click", { x: point.position.x, y: point.position.y, button: button })
    }
  }
  DragHandler {
    id: nativeDrag
    enabled: renderer && renderer.prop("enabled", true) !== false
    target: { var id = renderer ? String(renderer.prop("target", "")) : ""; return id === "" ? contentHost : renderer.findRenderedItem(id) }
    xAxis.enabled: !renderer || ["both", "horizontal", "x"].indexOf(String(renderer.prop("axis", "both"))) >= 0
    yAxis.enabled: !renderer || ["both", "vertical", "y"].indexOf(String(renderer.prop("axis", "both"))) >= 0
    xAxis.minimum: Number(renderer ? renderer.prop("minimum_x", -Infinity) : -Infinity); xAxis.maximum: Number(renderer ? renderer.prop("maximum_x", Infinity) : Infinity)
    yAxis.minimum: Number(renderer ? renderer.prop("minimum_y", -Infinity) : -Infinity); yAxis.maximum: Number(renderer ? renderer.prop("maximum_y", Infinity) : Infinity)
    dragThreshold: Number(renderer ? renderer.prop("threshold", 8) : 8)
    snapMode: dragRoot.snapMode(renderer ? renderer.prop("snap_mode", null) : null)
    cursorShape: flags.cursorShape(renderer ? renderer.prop("cursor", null) : null, "size_all")
    acceptedButtons: flags.buttons(renderer ? renderer.prop("accepted_buttons", null) : null, ["left"])
    acceptedDevices: flags.devices(renderer ? renderer.prop("accepted_devices", null) : null, ["all"])
    acceptedPointerTypes: flags.pointerTypes(renderer ? renderer.prop("accepted_pointer_types", null) : null, ["all"])
    acceptedModifiers: flags.modifiers(renderer ? renderer.prop("accepted_modifiers", null) : null, ["any"])
    minimumPointCount: Number(renderer ? renderer.prop("minimum_points", 1) : 1)
    maximumPointCount: Number(renderer ? renderer.prop("maximum_points", 1) : 1)
    function payload() {
      return {
        x: translation.x, y: translation.y,
        active_x: activeTranslation.x, active_y: activeTranslation.y,
        persistent_x: persistentTranslation.x, persistent_y: persistentTranslation.y,
        centroid_x: centroid.position.x, centroid_y: centroid.position.y,
        centroid_scene_x: centroid.scenePosition.x, centroid_scene_y: centroid.scenePosition.y
      }
    }
    onActiveChanged: {
      var resolved = payload()
      if (!active && target) { var snapX=Number(renderer.prop("snap_x",0));var snapY=Number(renderer.prop("snap_y",0));if(snapX>0)target.x=Math.round(target.x/snapX)*snapX;if(snapY>0)target.y=Math.round(target.y/snapY)*snapY;resolved.target_x=target.x;resolved.target_y=target.y }
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, active ? "drag_start" : "drag_end", resolved)
    }
    onTranslationChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "drag", payload())
    onCanceled: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "cancel", {})
  }

  Component.onCompleted: applyOptionalHandlerProperties()
  Connections { target: renderer; function onNodeChanged() { dragRoot.applyOptionalHandlerProperties() } }
}
