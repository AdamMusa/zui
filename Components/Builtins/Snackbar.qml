import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.Popup {
  id: snackbarRoot

  required property var renderer
  readonly property bool requestedOpen: renderer.prop("opened", false) === true
    && renderer.prop("visible", true) !== false
  readonly property real popupMargin: Number(renderer.prop("margin", Style.spacing.lg))
  readonly property real maximumWidth: Number(renderer.prop("max_width", 560))
  readonly property string popupPosition: String(renderer.prop("position", "bottom_center"))
  property real remainingDuration: 0
  property double timeoutDeadline: 0

  function syncOpenState() {
    if (requestedOpen === opened) return
    if (requestedOpen) open()
    else close()
  }

  function timed() {
    return renderer.prop("persistent", false) !== true
      && Number(renderer.prop("duration", 4000)) > 0
  }

  function startTimeout() {
    dismissTimer.stop()
    if (!visible || !timed()) return
    remainingDuration = Number(renderer.prop("duration", 4000))
    resumeTimeout()
  }

  function pauseTimeout() {
    if (!dismissTimer.running) return
    remainingDuration = Math.max(1, timeoutDeadline - Date.now())
    dismissTimer.stop()
  }

  function resumeTimeout() {
    if (!visible || !timed() || remainingDuration <= 0) return
    timeoutDeadline = Date.now() + remainingDuration
    dismissTimer.interval = remainingDuration
    dismissTimer.restart()
  }

  function dismiss(reason) {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "dismiss", { reason: reason })
    close()
  }

  x: {
    if (!parent) return popupMargin
    if (popupPosition.indexOf("left") >= 0) return popupMargin
    if (popupPosition.indexOf("right") >= 0) return parent.width - width - popupMargin
    return Math.max(popupMargin, (parent.width - width) / 2)
  }
  y: {
    if (!parent) return popupMargin
    if (popupPosition.indexOf("top") === 0) return popupMargin
    return parent.height - height - popupMargin
  }
  width: {
    var available = parent ? Math.max(0, parent.width - popupMargin * 2) : maximumWidth
    return Math.min(Number(renderer.prop("width", maximumWidth)), available, maximumWidth)
  }
  modal: false
  dim: false
  focus: false
  closePolicy: QQC.Popup.NoAutoClose
  enabled: renderer.prop("enabled", true) !== false
  padding: Number(renderer.prop("padding", Style.spacing.md))

  background: Rectangle {
    color: renderer.prop("background", Color.popups.background)
    radius: Number(renderer.prop("radius", Style.cornerRadius))
    border.width: String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0
    border.color: renderer.prop("border_color", "transparent")
  }

  contentItem: Row {
    spacing: Number(renderer.prop("spacing", Style.spacing.md))

    Text {
      width: Math.max(0, parent.width - (actionButton.visible ? actionButton.width + parent.spacing : 0))
      anchors.verticalCenter: parent.verticalCenter
      text: String(renderer.prop("message", ""))
      color: renderer.prop("foreground", renderer.foreground)
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
      wrapMode: Text.Wrap
    }

    QQC.Button {
      id: actionButton
      anchors.verticalCenter: parent.verticalCenter
      visible: text.length > 0
      text: String(renderer.prop("action_text", ""))
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
      contentItem: Text {
        text: actionButton.text
        color: renderer.prop("action_color", Color.accent)
        font: actionButton.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
      background: Rectangle { color: "transparent" }
      onClicked: {
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "action", {})
        if (renderer.prop("close_on_action", true) !== false) snackbarRoot.dismiss("action")
      }
    }
  }

  HoverHandler {
    enabled: renderer.prop("pause_on_hover", true) !== false
    onHoveredChanged: {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", { value: hovered })
      if (hovered) snackbarRoot.pauseTimeout()
      else snackbarRoot.resumeTimeout()
    }
  }

  Timer {
    id: dismissTimer
    repeat: false
    onTriggered: {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "timeout", {})
      snackbarRoot.dismiss("timeout")
    }
  }

  enter: Transition {
    ParallelAnimation {
      NumberAnimation {
        property: "opacity"; from: 0; to: 1
        duration: renderer.prop("animated", true) !== false
          ? Number(renderer.prop("animation_duration", 180)) : 0
        easing.type: renderer.easingType(renderer.prop("easing", "out_cubic"))
      }
      NumberAnimation {
        property: "scale"; from: 0.96; to: 1
        duration: renderer.prop("animated", true) !== false
          ? Number(renderer.prop("animation_duration", 180)) : 0
        easing.type: renderer.easingType(renderer.prop("easing", "out_cubic"))
      }
    }
  }

  exit: Transition {
    ParallelAnimation {
      NumberAnimation {
        property: "opacity"; from: 1; to: 0
        duration: renderer.prop("animated", true) !== false
          ? Number(renderer.prop("animation_duration", 140)) : 0
        easing.type: renderer.easingType("in_cubic")
      }
      NumberAnimation {
        property: "scale"; from: 1; to: 0.96
        duration: renderer.prop("animated", true) !== false
          ? Number(renderer.prop("animation_duration", 140)) : 0
        easing.type: renderer.easingType("in_cubic")
      }
    }
  }

  Component.onCompleted: syncOpenState()
  onRequestedOpenChanged: syncOpenState()
  onOpened: {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "open", {})
    startTimeout()
  }
  onClosed: {
    dismissTimer.stop()
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "close", {})
  }
  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
}
