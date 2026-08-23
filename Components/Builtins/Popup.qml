import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.Popup {
  id: popupRoot

  required property var renderer
  readonly property bool requestedOpen: renderer.prop("opened", false) === true
    && renderer.prop("visible", true) !== false
  readonly property string contentLayout: String(renderer.prop("layout", "column"))

  function closePolicyValue(value) {
    var names = Array.isArray(value) ? value : [value || "escape_and_outside"]
    var result = 0
    for (var index = 0; index < names.length; index++) {
      var name = String(names[index])
      if (name === "escape" || name === "escape_and_outside") result |= QQC.Popup.CloseOnEscape
      if (name === "outside" || name === "escape_and_outside") result |= QQC.Popup.CloseOnPressOutside
      if (name === "outside_parent") result |= QQC.Popup.CloseOnPressOutsideParent
      if (name === "release_outside") result |= QQC.Popup.CloseOnReleaseOutside
      if (name === "release_outside_parent") result |= QQC.Popup.CloseOnReleaseOutsideParent
    }
    return result
  }

  function syncOpenState() {
    if (requestedOpen === opened) return
    if (requestedOpen) open()
    else close()
  }

  x: Number(renderer.prop("x", 0))
  y: Number(renderer.prop("y", 0))
  width: Number(renderer.prop("width", 360))
  height: Number(renderer.prop("height", 240))
  modal: renderer.prop("modal", false) === true
  dim: renderer.prop("dim", modal) !== false
  focus: renderer.prop("focus", true) !== false
  closePolicy: closePolicyValue(renderer.prop("close_policy", "escape_and_outside"))
  enabled: renderer.prop("enabled", true) !== false
  padding: Number(renderer.prop("padding", Style.spacing.lg))

  background: Rectangle {
    color: renderer.prop("background", Color.background)
    radius: Number(renderer.prop("radius", Style.cornerRadius))
    border.width: String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0
    border.color: renderer.prop("border_color", "transparent")
  }

  contentItem: Loader {
    sourceComponent: popupRoot.contentLayout === "row" ? rowContent
      : (popupRoot.contentLayout === "stack" ? stackContent : columnContent)
  }

  Component {
    id: columnContent
    Column {
      spacing: Number(renderer.prop("spacing", Style.spacing.md))
      Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
    }
  }

  Component {
    id: rowContent
    Row {
      spacing: Number(renderer.prop("spacing", Style.spacing.md))
      Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
    }
  }

  Component {
    id: stackContent
    Item {
      Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
    }
  }

  enter: Transition {
    ParallelAnimation {
      NumberAnimation {
        property: "opacity"; from: 0; to: 1
        duration: renderer.prop("animated", true) !== false
          ? Number(renderer.prop("duration", 160)) : 0
        easing.type: renderer.easingType(renderer.prop("easing", "out_cubic"))
      }
      NumberAnimation {
        property: "scale"; from: 0.96; to: 1
        duration: renderer.prop("animated", true) !== false
          ? Number(renderer.prop("duration", 160)) : 0
        easing.type: renderer.easingType(renderer.prop("easing", "out_cubic"))
      }
    }
  }
  exit: Transition {
    ParallelAnimation {
      NumberAnimation {
        property: "opacity"; from: 1; to: 0
        duration: renderer.prop("animated", true) !== false
          ? Number(renderer.prop("duration", 120)) : 0
        easing.type: renderer.easingType(renderer.prop("easing", "in_cubic"))
      }
      NumberAnimation {
        property: "scale"; from: 1; to: 0.96
        duration: renderer.prop("animated", true) !== false
          ? Number(renderer.prop("duration", 120)) : 0
        easing.type: renderer.easingType(renderer.prop("easing", "in_cubic"))
      }
    }
  }

  Component.onCompleted: syncOpenState()
  onRequestedOpenChanged: syncOpenState()
  onOpened: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "open", {})
  onClosed: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "close", {})
  onAboutToShow: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "about_to_show", {})
  onAboutToHide: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "about_to_hide", {})
  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
  onActiveFocusChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    activeFocus ? "focus" : "blur", {})
  onXChanged: {
    if (renderer.subscribed("position_change"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "position_change", { x: x, y: y })
  }
  onYChanged: {
    if (renderer.subscribed("position_change"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "position_change", { x: x, y: y })
  }
}
