import QtQuick

Item {
  id: mouseRoot
  required property var renderer
  implicitWidth: Number(renderer.prop("width", contentHost.childrenRect.width || 44))
  implicitHeight: Number(renderer.prop("height", contentHost.childrenRect.height || 44))

  function buttons(requested) {
    var values = Array.isArray(requested) ? requested : [requested || "left"]
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

  function cursorShape(requested) {
    var name = String(requested || "arrow")
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

  function dragAxis(requested) {
    var name = String(requested || "both")
    if (name === "horizontal" || name === "x") return Drag.XAxis
    if (name === "vertical" || name === "y") return Drag.YAxis
    return Drag.XAndYAxis
  }

  function dragTarget() {
    var identifier = String(renderer.prop("drag_target", ""))
    return identifier === "" ? null : renderer.findRenderedItem(identifier)
  }

  Item {
    id: contentHost
    anchors.fill: parent
    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  }

  MouseArea {
    id: nativeMouse
    anchors.fill: parent
    enabled: renderer.prop("enabled", true) !== false
    hoverEnabled: renderer.prop("hover_enabled", false) === true
    acceptedButtons: mouseRoot.buttons(renderer.prop("accepted_buttons", ["left"]))
    pressAndHoldInterval: Number(renderer.prop("press_and_hold_interval", 800))
    cursorShape: mouseRoot.cursorShape(renderer.prop("cursor", "arrow"))
    propagateComposedEvents: renderer.prop("propagate_composed_events", false) === true
    preventStealing: renderer.prop("prevent_stealing", false) === true
    scrollGestureEnabled: renderer.prop("scroll_gesture_enabled", true) !== false

    drag.target: mouseRoot.dragTarget()
    drag.axis: mouseRoot.dragAxis(renderer.prop("drag_axis", "both"))
    drag.minimumX: Number(renderer.prop("drag_minimum_x", -Infinity))
    drag.maximumX: Number(renderer.prop("drag_maximum_x", Infinity))
    drag.minimumY: Number(renderer.prop("drag_minimum_y", -Infinity))
    drag.maximumY: Number(renderer.prop("drag_maximum_y", Infinity))
    drag.filterChildren: renderer.prop("drag_filter_children", false) === true
    drag.smoothed: renderer.prop("drag_smoothed", true) !== false
    drag.threshold: Number(renderer.prop("drag_threshold", 10))

    function mousePayload(mouse) {
      return {
        x: mouse.x, y: mouse.y, button: Number(mouse.button),
        buttons: Number(mouse.buttons), modifiers: Number(mouse.modifiers),
        was_held: mouse.wasHeld === true
      }
    }

    function pointerPayload() {
      return {
        x: mouseX, y: mouseY, buttons: Number(pressedButtons),
        contains_mouse: containsMouse, contains_press: containsPress
      }
    }

    onClicked: function (mouse) {
      if (renderer.subscribed("click"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", mousePayload(mouse))
    }
    onDoubleClicked: function (mouse) {
      if (renderer.subscribed("double_click"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "double_click", mousePayload(mouse))
    }
    onPressed: function (mouse) {
      if (renderer.subscribed("press"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "press", mousePayload(mouse))
    }
    onReleased: function (mouse) {
      if (renderer.subscribed("release"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "release", mousePayload(mouse))
    }
    onPressAndHold: function (mouse) {
      if (renderer.subscribed("press_and_hold"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "press_and_hold", mousePayload(mouse))
    }
    onPositionChanged: function (mouse) {
      if (renderer.subscribed("move"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "move", mousePayload(mouse))
    }
    onWheel: function (wheel) {
      if (renderer.subscribed("wheel"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "wheel", {
          x: wheel.x, y: wheel.y, angle_x: wheel.angleDelta.x, angle_y: wheel.angleDelta.y,
          pixel_x: wheel.pixelDelta.x, pixel_y: wheel.pixelDelta.y,
          buttons: Number(wheel.buttons), modifiers: Number(wheel.modifiers),
          inverted: wheel.inverted === true
        })
    }
    onEntered: {
      if (renderer.subscribed("enter"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "enter", pointerPayload())
    }
    onExited: {
      if (renderer.subscribed("exit"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "exit", pointerPayload())
    }
    onCanceled: {
      if (renderer.subscribed("cancel"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "cancel", pointerPayload())
    }
    onPressedChanged: {
      if (renderer.subscribed("pressed_change"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "pressed_change", {
          value: pressed, buttons: Number(pressedButtons), contains_press: containsPress
        })
    }

    Connections {
      target: nativeMouse.drag
      enabled: renderer.subscribed("drag_change")
      function onActiveChanged() {
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "drag_change", {
          value: nativeMouse.drag.active,
          target_x: nativeMouse.drag.target ? nativeMouse.drag.target.x : 0,
          target_y: nativeMouse.drag.target ? nativeMouse.drag.target.y : 0
        })
      }
    }
  }
}
