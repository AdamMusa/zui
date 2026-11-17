import QtQuick

// The drag half of drag and drop: the Item.Drag attached property, which
// carries the payload a drop_area receives. drag_area wraps DragHandler and
// only moves an item inside its own parent; it transfers nothing.
Item {
  id: dragSourceRoot
  required property var renderer
  property int handledCommandRevision: -1
  implicitWidth: Number(renderer.prop("width", payload.childrenRect.width || 80))
  implicitHeight: Number(renderer.prop("height", payload.childrenRect.height || 80))

  function dragType() {
    var requested = String(renderer.prop("drag_type", "internal"))
    if (requested === "automatic") return Drag.Automatic
    if (requested === "none") return Drag.None
    return Drag.Internal
  }

  function dropAction(requested) {
    var name = String(requested || "")
    if (name === "copy") return Qt.CopyAction
    if (name === "link") return Qt.LinkAction
    if (name === "ignore") return Qt.IgnoreAction
    if (name === "target_move") return Qt.TargetMoveAction
    return Qt.MoveAction
  }

  function dropActionName(value) {
    if (value === Qt.CopyAction) return "copy"
    if (value === Qt.LinkAction) return "link"
    if (value === Qt.TargetMoveAction) return "target_move"
    if (value === Qt.MoveAction) return "move"
    return "ignore"
  }

  function supportedActions() {
    var requested = renderer.prop("supported_actions", null)
    var values = Array.isArray(requested) ? requested : null
    if (!values) return Qt.MoveAction | Qt.CopyAction
    var result = Qt.IgnoreAction
    for (var index = 0; index < values.length; index++) result |= dragSourceRoot.dropAction(values[index])
    return result
  }

  // One binding owns Drag.active, so an explicit `active` from Ruby and the
  // built-in handler cannot fight each other over it.
  function wantsActive() {
    if (renderer.prop("enabled", true) === false) return false
    if (renderer.hasProp("active")) return renderer.prop("active", false) === true
    return internalDrag.active
  }

  function applyDragThreshold() {
    if (!renderer.hasProp("threshold")) return
    internalDrag.dragThreshold = Number(renderer.prop("threshold", 0))
  }

  function processCommand() {
    var revision = Number(renderer.prop("command_revision", 0))
    if (revision === handledCommandRevision) return
    var first = handledCommandRevision < 0
    handledCommandRevision = revision
    if (first && revision <= 0) return
    var command = String(renderer.prop("command", ""))
    if (command === "start_drag") payload.Drag.startDrag(dragSourceRoot.supportedActions())
    else if (command === "cancel") payload.Drag.cancel()
    else if (command === "drop") {
      var action = payload.Drag.drop()
      if (renderer.subscribed("drop_result"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "drop_result",
          { action: dragSourceRoot.dropActionName(action) })
    }
  }

  function resetPosition() {
    if (renderer.prop("reset_on_finish", true) === false) return
    payload.x = 0
    payload.y = 0
  }

  Item {
    id: payload
    // Not anchored: the built-in DragHandler has to be able to move this item,
    // which is what lets Qt find the drop_area underneath it.
    width: dragSourceRoot.width
    height: dragSourceRoot.height

    Drag.active: dragSourceRoot.wantsActive()
    Drag.dragType: dragSourceRoot.dragType()
    Drag.source: dragSourceRoot
    Drag.keys: renderer.prop("keys", [])
    Drag.mimeData: renderer.prop("mime_data", ({}))
    Drag.supportedActions: dragSourceRoot.supportedActions()
    Drag.proposedAction: dragSourceRoot.dropAction(renderer.prop("proposed_action", "move"))
    Drag.hotSpot: Qt.point(Number(renderer.prop("hot_spot_x", 0)), Number(renderer.prop("hot_spot_y", 0)))
    Drag.imageSource: String(renderer.prop("image_source", ""))
    Drag.imageSourceSize: Qt.size(Number(renderer.prop("image_source_width", -1)),
                                  Number(renderer.prop("image_source_height", -1)))

    Drag.onDragStarted: {
      if (renderer.subscribed("drag_start"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "drag_start",
          { x: payload.x, y: payload.y })
    }
    Drag.onDragFinished: function (action) {
      if (renderer.subscribed("drag_finish"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "drag_finish", {
          action: dragSourceRoot.dropActionName(action),
          dropped: action !== Qt.IgnoreAction,
          x: payload.x, y: payload.y
        })
      dragSourceRoot.resetPosition()
    }
    Drag.onActiveChanged: {
      if (renderer.subscribed("active_change"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "active_change",
          { value: payload.Drag.active })
    }
    Drag.onTargetChanged: {
      if (renderer.subscribed("target_change"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "target_change",
          { over_drop_area: payload.Drag.target !== null })
    }

    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }

    DragHandler {
      id: internalDrag
      enabled: renderer.prop("enabled", true) !== false && !renderer.hasProp("active")
      xAxis.enabled: ["both", "horizontal", "x"].indexOf(String(renderer.prop("axis", "both"))) >= 0
      yAxis.enabled: ["both", "vertical", "y"].indexOf(String(renderer.prop("axis", "both"))) >= 0
    }
  }

  Component.onCompleted: { applyDragThreshold(); processCommand() }
  Connections { target: renderer; function onNodeChanged() { dragSourceRoot.applyDragThreshold(); dragSourceRoot.processCommand() } }
}
