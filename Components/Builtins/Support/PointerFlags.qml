import QtQuick

// Shared translations for the QQuickPointerHandler and
// QQuickPointerDeviceHandler flag properties, so every handler adapter
// exposes the same vocabulary instead of a per-adapter subset.
QtObject {
  function list(requested, fallback) {
    if (Array.isArray(requested)) return requested
    if (requested === null || requested === undefined) return fallback
    return [requested]
  }

  function buttons(requested, fallback) {
    var values = list(requested, fallback)
    var result = Qt.NoButton
    for (var index = 0; index < values.length; index++) {
      var name = String(values[index])
      if (name === "left") result |= Qt.LeftButton
      else if (name === "right") result |= Qt.RightButton
      else if (name === "middle") result |= Qt.MiddleButton
      else if (name === "back") result |= Qt.BackButton
      else if (name === "forward") result |= Qt.ForwardButton
      else if (name === "all") result |= Qt.AllButtons
    }
    return result
  }

  function devices(requested, fallback) {
    var values = list(requested, fallback)
    var result = PointerDevice.Unknown
    for (var index = 0; index < values.length; index++) {
      var name = String(values[index])
      if (name === "mouse") result |= PointerDevice.Mouse
      else if (name === "touch_screen") result |= PointerDevice.TouchScreen
      else if (name === "touch_pad") result |= PointerDevice.TouchPad
      else if (name === "stylus") result |= PointerDevice.Stylus
      else if (name === "airbrush") result |= PointerDevice.Airbrush
      else if (name === "puck") result |= PointerDevice.Puck
      else if (name === "keyboard") result |= PointerDevice.Keyboard
      else if (name === "all") result |= PointerDevice.AllDevices
    }
    return result
  }

  function pointerTypes(requested, fallback) {
    var values = list(requested, fallback)
    var result = PointerDevice.Unknown
    for (var index = 0; index < values.length; index++) {
      var name = String(values[index])
      if (name === "generic") result |= PointerDevice.Generic
      else if (name === "finger") result |= PointerDevice.Finger
      else if (name === "pen") result |= PointerDevice.Pen
      else if (name === "eraser") result |= PointerDevice.Eraser
      else if (name === "cursor") result |= PointerDevice.Cursor
      else if (name === "all") result |= PointerDevice.AllPointerTypes
    }
    return result
  }

  function modifiers(requested, fallback) {
    var values = list(requested, fallback)
    var result = Qt.NoModifier
    for (var index = 0; index < values.length; index++) {
      var name = String(values[index])
      if (name === "shift") result |= Qt.ShiftModifier
      else if (name === "control") result |= Qt.ControlModifier
      else if (name === "alt") result |= Qt.AltModifier
      else if (name === "meta") result |= Qt.MetaModifier
      else if (name === "keypad") result |= Qt.KeypadModifier
      else if (name === "group_switch") result |= Qt.GroupSwitchModifier
      else if (name === "any") result |= Qt.KeyboardModifierMask
    }
    return result
  }

  function grabPermissions(requested, fallback) {
    var values = list(requested, fallback)
    var result = PointerHandler.TakeOverForbidden
    for (var index = 0; index < values.length; index++) {
      var name = String(values[index])
      if (name === "can_take_over_from_same_type") result |= PointerHandler.CanTakeOverFromHandlersOfSameType
      else if (name === "can_take_over_from_different_type") result |= PointerHandler.CanTakeOverFromHandlersOfDifferentType
      else if (name === "can_take_over_from_items") result |= PointerHandler.CanTakeOverFromItems
      else if (name === "can_take_over_from_anything") result |= PointerHandler.CanTakeOverFromAnything
      else if (name === "approves_take_over_by_same_type") result |= PointerHandler.ApprovesTakeOverByHandlersOfSameType
      else if (name === "approves_take_over_by_different_type") result |= PointerHandler.ApprovesTakeOverByHandlersOfDifferentType
      else if (name === "approves_take_over_by_items") result |= PointerHandler.ApprovesTakeOverByItems
      else if (name === "approves_cancellation") result |= PointerHandler.ApprovesCancellation
    }
    return result
  }

  function cursorShape(requested, fallback) {
    var name = String(requested === null || requested === undefined ? fallback : requested)
    if (name === "pointing_hand") return Qt.PointingHandCursor
    if (name === "cross") return Qt.CrossCursor
    if (name === "text") return Qt.IBeamCursor
    if (name === "wait") return Qt.WaitCursor
    if (name === "busy") return Qt.BusyCursor
    if (name === "open_hand") return Qt.OpenHandCursor
    if (name === "closed_hand") return Qt.ClosedHandCursor
    if (name === "forbidden") return Qt.ForbiddenCursor
    if (name === "what_is_this") return Qt.WhatsThisCursor
    if (name === "size_all") return Qt.SizeAllCursor
    if (name === "size_horizontal") return Qt.SizeHorCursor
    if (name === "size_vertical") return Qt.SizeVerCursor
    if (name === "split_horizontal") return Qt.SplitHCursor
    if (name === "split_vertical") return Qt.SplitVCursor
    if (name === "blank") return Qt.BlankCursor
    if (name === "up_arrow") return Qt.UpArrowCursor
    if (name === "drag_move") return Qt.DragMoveCursor
    if (name === "drag_copy") return Qt.DragCopyCursor
    if (name === "drag_link") return Qt.DragLinkCursor
    return Qt.ArrowCursor
  }

  // Everything QQuickHandlerPoint carries, so handler events do not have to
  // pick a subset per adapter.
  function handlerPoint(point) {
    return {
      x: point.position.x, y: point.position.y,
      scene_x: point.scenePosition.x, scene_y: point.scenePosition.y,
      press_x: point.pressPosition.x, press_y: point.pressPosition.y,
      velocity_x: point.velocity.x, velocity_y: point.velocity.y,
      pressure: point.pressure, rotation: point.rotation,
      ellipse_width: point.ellipseDiameters.width,
      ellipse_height: point.ellipseDiameters.height,
      modifiers: Number(point.modifiers),
      pressed_buttons: Number(point.pressedButtons)
    }
  }
}
