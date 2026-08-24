import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"

QQC.Popup {
  id: toastRoot

  required property var renderer
  readonly property bool requestedOpen: renderer.prop("opened", false) === true
    && renderer.prop("visible", true) !== false
  readonly property string severity: String(renderer.prop("severity", "info"))
  readonly property string popupPosition: String(renderer.prop("position", "top_right"))
  readonly property real popupMargin: Number(renderer.prop("margin", Style.spacing.lg))
  readonly property real maximumWidth: Number(renderer.prop("max_width", 420))
  property real remainingDuration: 0
  property double timeoutDeadline: 0

  function severityIcon() {
    var explicitIcon = String(renderer.prop("icon", ""))
    if (explicitIcon.length > 0) return explicitIcon
    if (severity === "success") return "circle_check"
    if (severity === "warning") return "warning"
    if (severity === "error" || severity === "critical") return "circle_xmark"
    return "circle_info"
  }

  function severityColor() {
    if (severity === "success") return renderer.prop("success_color", renderer.prop("accent", Color.accent))
    if (severity === "warning") return renderer.prop("warning_color", "#d8a657")
    if (severity === "error" || severity === "critical") return renderer.prop("error_color", Color.urgent)
    return renderer.prop("accent", Color.accent)
  }

  function syncOpenState() {
    if (requestedOpen === opened) return
    if (requestedOpen) open()
    else close()
  }

  function timed() {
    return renderer.prop("persistent", false) !== true
      && Number(renderer.prop("duration", 3500)) > 0
  }

  function startTimeout() {
    dismissTimer.stop()
    if (!visible || !timed()) return
    remainingDuration = Number(renderer.prop("duration", 3500))
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
    if (popupPosition.indexOf("bottom") === 0) return parent.height - height - popupMargin
    return popupMargin
  }
  width: {
    var available = parent ? Math.max(0, parent.width - popupMargin * 2) : maximumWidth
    return Math.min(Number(renderer.prop("width", 360)), available, maximumWidth)
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
    border.width: Style.normalBorderWidth
    border.color: renderer.prop("border_color", toastRoot.severityColor())
  }

  contentItem: RowLayout {
    spacing: Number(renderer.prop("spacing", Style.spacing.md))

    Text {
      Layout.alignment: Qt.AlignTop
      text: renderer.iconGlyph(toastRoot.severityIcon())
      textFormat: Text.PlainText
      color: toastRoot.severityColor()
      font.family: renderer.iconFontFamily
      font.pixelSize: Number(renderer.prop("icon_size", 22))
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.spacing.xs

      Text {
        Layout.fillWidth: true
        visible: text.length > 0
        text: String(renderer.prop("title", ""))
        textFormat: Text.PlainText
        color: renderer.prop("foreground", renderer.foreground)
        font.family: String(renderer.prop("font_family", renderer.fontFamily))
        font.pixelSize: Number(renderer.prop("title_size", Style.font.body))
        font.bold: true
        wrapMode: Text.Wrap
      }

      Text {
        Layout.fillWidth: true
        text: String(renderer.prop("message", ""))
        textFormat: Text.PlainText
        color: String(renderer.prop("title", "")).length > 0
          ? renderer.prop("muted", Color.muted)
          : renderer.prop("foreground", renderer.foreground)
        font.family: String(renderer.prop("font_family", renderer.fontFamily))
        font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
        wrapMode: Text.Wrap
      }
    }
  }

  TapHandler {
    onTapped: {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", {})
      if (renderer.prop("dismiss_on_click", true) !== false) toastRoot.dismiss("click")
    }
  }

  HoverHandler {
    enabled: renderer.prop("pause_on_hover", true) !== false
    onHoveredChanged: {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", { value: hovered })
      if (hovered) toastRoot.pauseTimeout()
      else toastRoot.resumeTimeout()
    }
  }

  Timer {
    id: dismissTimer
    repeat: false
    onTriggered: {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "timeout", {})
      toastRoot.dismiss("timeout")
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
        property: "scale"; from: 0.94; to: 1
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
        property: "scale"; from: 1; to: 0.94
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
