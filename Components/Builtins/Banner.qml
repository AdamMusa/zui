import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"

QQC.Pane {
  id: bannerRoot

  required property var renderer
  readonly property string severity: String(renderer.prop("severity", "info"))
  readonly property bool requestedVisible: renderer.prop("visible", true) !== false
  property bool locallyDismissed: false

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

  visible: requestedVisible && !locallyDismissed
  implicitWidth: Number(renderer.prop("width", 640))
  implicitHeight: renderer.prop("height", null) === null
    ? contentRow.implicitHeight + topPadding + bottomPadding
    : Number(renderer.prop("height", 88))
  enabled: renderer.prop("enabled", true) !== false
  padding: Number(renderer.prop("padding", Style.spacing.md))

  background: Rectangle {
    color: renderer.prop("background", Color.popups.background)
    radius: Number(renderer.prop("radius", Style.cornerRadius))
    border.width: Style.normalBorderWidth
    border.color: renderer.prop("border_color", bannerRoot.severityColor())
  }

  contentItem: RowLayout {
    id: contentRow
    spacing: Number(renderer.prop("spacing", Style.spacing.md))

    Text {
      Layout.alignment: Qt.AlignTop
      text: renderer.iconGlyph(bannerRoot.severityIcon())
      textFormat: Text.PlainText
      color: bannerRoot.severityColor()
      font.family: renderer.iconFontFamily
      font.pixelSize: Number(renderer.prop("icon_size", 24))
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
        font.pixelSize: Number(renderer.prop("title_size", Style.font.heading))
        font.bold: true
        wrapMode: Text.Wrap
      }

      Text {
        Layout.fillWidth: true
        text: String(renderer.prop("message", ""))
        textFormat: Text.PlainText
        color: renderer.prop("muted", renderer.prop("foreground", renderer.foreground))
        font.family: String(renderer.prop("font_family", renderer.fontFamily))
        font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
        wrapMode: Text.Wrap
      }
    }

    QQC.Button {
      id: actionButton
      Layout.alignment: Qt.AlignVCenter
      visible: text.length > 0
      text: String(renderer.prop("action_text", ""))
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
      contentItem: Text {
        text: actionButton.text
        color: renderer.prop("action_color", bannerRoot.severityColor())
        font: actionButton.font
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
      background: Rectangle { color: "transparent" }
      onClicked: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "action", {})
    }

    QQC.ToolButton {
      Layout.alignment: Qt.AlignTop
      visible: renderer.prop("dismissible", true) !== false
      text: renderer.iconGlyph("xmark")
      font.family: renderer.iconFontFamily
      font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
      onClicked: {
        bannerRoot.locallyDismissed = true
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "dismiss", {})
      }
    }
  }

  TapHandler {
    enabled: renderer.subscribed("click")
    onTapped: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", {})
  }

  HoverHandler {
    onHoveredChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "hover", { value: hovered })
  }

  onRequestedVisibleChanged: {
    if (!requestedVisible) locallyDismissed = false
  }
  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
  onActiveFocusChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    activeFocus ? "focus" : "blur", {})
}
