import QtQuick

Item {
  id: dragRoot
  property var renderer: null
  function cursorShape(name) { var value=String(name||"size_all");if(value==="arrow")return Qt.ArrowCursor;if(value==="pointing_hand")return Qt.PointingHandCursor;if(value==="open_hand")return Qt.OpenHandCursor;if(value==="closed_hand")return Qt.ClosedHandCursor;if(value==="horizontal")return Qt.SizeHorCursor;if(value==="vertical")return Qt.SizeVerCursor;return Qt.SizeAllCursor }
  implicitWidth: Number(renderer ? renderer.prop("width", contentHost.childrenRect.width) : 120)
  implicitHeight: Number(renderer ? renderer.prop("height", contentHost.childrenRect.height) : 80)
  property int resetRevision: Number(renderer ? renderer.prop("reset_revision", 0) : 0)
  onResetRevisionChanged: {
    var item = nativeDrag.target
    if (item) { item.x = 0; item.y = 0 }
  }
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
    cursorShape: dragRoot.cursorShape(renderer ? renderer.prop("cursor", "size_all") : "size_all")
    onActiveChanged: {
      var payload = { x: translation.x, y: translation.y, centroid_x: centroid.position.x, centroid_y: centroid.position.y }
      if (!active && target) { var snapX=Number(renderer.prop("snap_x",0));var snapY=Number(renderer.prop("snap_y",0));if(snapX>0)target.x=Math.round(target.x/snapX)*snapX;if(snapY>0)target.y=Math.round(target.y/snapY)*snapY;payload.target_x=target.x;payload.target_y=target.y }
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, active ? "drag_start" : "drag_end", payload)
    }
    onTranslationChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "drag", { x: translation.x, y: translation.y, centroid_x: centroid.position.x, centroid_y: centroid.position.y })
    onCanceled: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "cancel", {})
  }
}
