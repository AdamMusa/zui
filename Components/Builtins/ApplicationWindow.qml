import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Window

QQC.ApplicationWindow {
  id: nativeWindow

  required property var renderer

  function visibilityValue(value) {
    var name = String(value || "automatic")
    if (name === "hidden") return Window.Hidden
    if (name === "minimized") return Window.Minimized
    if (name === "maximized") return Window.Maximized
    if (name === "fullscreen" || name === "full_screen") return Window.FullScreen
    if (name === "windowed") return Window.Windowed
    return Window.AutomaticVisibility
  }

  function modalityValue(value) {
    var name = String(value || "none")
    if (name === "window" || name === "window_modal") return Qt.WindowModal
    if (name === "application" || name === "application_modal") return Qt.ApplicationModal
    return Qt.NonModal
  }

  function flagsValue(value) {
    if (typeof value === "number") return value
    var names = Array.isArray(value) ? value : [value || "window"]
    var result = 0
    for (var index = 0; index < names.length; index++) {
      var name = String(names[index])
      if (name === "dialog") result |= Qt.Dialog
      else if (name === "sheet") result |= Qt.Sheet
      else if (name === "drawer") result |= Qt.Drawer
      else if (name === "popup") result |= Qt.Popup
      else if (name === "tool") result |= Qt.Tool
      else if (name === "tooltip") result |= Qt.ToolTip
      else if (name === "splash") result |= Qt.SplashScreen
      else if (name === "frameless") result |= Qt.FramelessWindowHint
      else if (name === "stay_on_top") result |= Qt.WindowStaysOnTopHint
      else if (name === "stay_on_bottom") result |= Qt.WindowStaysOnBottomHint
      else result |= Qt.Window
    }
    return result || Qt.Window
  }

  function orientationValue(value) {
    var name = String(value || "primary")
    if (name === "portrait") return Qt.PortraitOrientation
    if (name === "landscape") return Qt.LandscapeOrientation
    if (name === "inverted_portrait") return Qt.InvertedPortraitOrientation
    if (name === "inverted_landscape") return Qt.InvertedLandscapeOrientation
    return Qt.PrimaryOrientation
  }

  title: String(renderer.prop("title", ""))
  x: Number(renderer.prop("x", 0))
  y: Number(renderer.prop("y", 0))
  width: Number(renderer.prop("width", 800))
  height: Number(renderer.prop("height", 600))
  minimumWidth: Number(renderer.prop("minimum_width", 0))
  minimumHeight: Number(renderer.prop("minimum_height", 0))
  maximumWidth: Number(renderer.prop("maximum_width", 16777215))
  maximumHeight: Number(renderer.prop("maximum_height", 16777215))
  color: renderer.prop("color", "transparent")
  visible: renderer.prop("visible", false) === true
  visibility: visibilityValue(renderer.prop("visibility", "automatic"))
  modality: modalityValue(renderer.prop("modality", "none"))
  flags: flagsValue(renderer.prop("flags", "window"))
  opacity: Number(renderer.prop("opacity", 1))
  contentOrientation: orientationValue(renderer.prop("content_orientation", "primary"))
  font.family: String(renderer.prop("font_family", renderer.fontFamily))
  font.pixelSize: Number(renderer.prop("font_size", 14))
  background: Rectangle { color: renderer.prop("background", "transparent") }

  onClosing: function(close) {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "close", {
      accepted: close.accepted
    })
  }
  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "visible_change", { value: visible })
  onActiveChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "active_change", { value: active })
  onVisibilityChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "visibility_change", { value: visibility })
  onActiveFocusControlChanged: if (renderer.subscribed("focus_change")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "focus_change", {
    active: activeFocusControl !== null,
    object_name: activeFocusControl ? String(activeFocusControl.objectName || "") : ""
  })
  onXChanged: if (renderer.subscribed("move")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "move", { x: x, y: y })
  onYChanged: if (renderer.subscribed("move")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "move", { x: x, y: y })
  onWidthChanged: if (renderer.subscribed("resize")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "resize", { width: width, height: height })
  onHeightChanged: if (renderer.subscribed("resize")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "resize", { width: width, height: height })

  Item {
    anchors.fill: parent
    LayoutMirroring.enabled: String(renderer.prop("layout_direction", "left_to_right")) === "right_to_left"
    LayoutMirroring.childrenInherit: true
    Repeater {
      model: renderer.node.children || []
      delegate: renderer.childDelegateComponent
    }
  }
}
