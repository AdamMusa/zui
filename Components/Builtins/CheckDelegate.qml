import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"

QQC.CheckDelegate {
  id: checkRoot

  required property var renderer
  readonly property bool selected: renderer.prop("selected", false) === true
  readonly property real indicatorSize: Number(renderer.prop("indicator_size", 22))

  function checkStateValue(value) {
    if (value === Qt.Checked || String(value) === "checked" || value === true) return Qt.Checked
    if (value === Qt.PartiallyChecked || String(value) === "partial"
        || String(value) === "partially_checked") return Qt.PartiallyChecked
    return Qt.Unchecked
  }

  function checkStateName() {
    if (checkState === Qt.Checked) return "checked"
    if (checkState === Qt.PartiallyChecked) return "partial"
    return "unchecked"
  }

  function eventPayload() {
    return {
      text: text,
      value: renderer.prop("value", text),
      checked: checkState === Qt.Checked,
      check_state: checkStateName(),
      selected: selected
    }
  }

  text: String(renderer.prop("text", ""))
  tristate: renderer.prop("tristate", false) === true
  checkState: checkStateValue(renderer.prop("check_state",
    renderer.prop("checked", false) === true ? "checked" : "unchecked"))
  highlighted: renderer.prop("highlighted", selected) === true
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false
  hoverEnabled: true
  implicitWidth: Number(renderer.prop("width", 320))
  implicitHeight: Number(renderer.prop("height", 56))
  padding: Number(renderer.prop("padding", Style.spacing.md))
  rightPadding: padding + indicatorSize + Number(renderer.prop("spacing", Style.spacing.md))
  font.family: String(renderer.prop("font_family", renderer.fontFamily))
  font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
  Accessible.name: String(renderer.prop("accessible_name", text))

  background: Rectangle {
    color: checkRoot.highlighted
      ? renderer.prop("highlighted_background", renderer.prop("selected_background", Color.popups.background))
      : (checkRoot.selected
        ? renderer.prop("selected_background", Color.popups.background)
        : renderer.prop("background", "transparent"))
    radius: Number(renderer.prop("radius", Style.cornerRadius))
    border.width: Number(renderer.prop("border_width",
      String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0))
    border.color: renderer.prop("border_color", "transparent")
  }

  contentItem: ColumnLayout {
    spacing: Style.spacing.xs

    Text {
      Layout.fillWidth: true
      text: checkRoot.text
      textFormat: Text.PlainText
      color: checkRoot.selected
        ? renderer.prop("selected_foreground", renderer.prop("foreground", renderer.foreground))
        : renderer.prop("foreground", renderer.foreground)
      font: checkRoot.font
      elide: Text.ElideRight
    }

    Text {
      Layout.fillWidth: true
      visible: text.length > 0
      text: String(renderer.prop("description", ""))
      textFormat: Text.PlainText
      color: renderer.prop("muted", Color.muted)
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("description_size", Style.font.caption))
      elide: Text.ElideRight
    }
  }

  indicator: Rectangle {
    x: checkRoot.width - checkRoot.rightPadding + Number(renderer.prop("spacing", Style.spacing.md))
    y: (checkRoot.height - height) / 2
    width: checkRoot.indicatorSize
    height: checkRoot.indicatorSize
    radius: Number(renderer.prop("radius", 4))
    color: checkRoot.checkState === Qt.Unchecked
      ? renderer.prop("indicator_background", "transparent")
      : renderer.prop("accent", Color.accent)
    border.width: Style.normalBorderWidth
    border.color: renderer.prop("indicator_border",
      checkRoot.checkState === Qt.Unchecked ? renderer.foreground : renderer.prop("accent", Color.accent))

    Text {
      anchors.centerIn: parent
      visible: checkRoot.checkState !== Qt.Unchecked
      text: checkRoot.checkState === Qt.PartiallyChecked ? "−" : renderer.iconGlyph("check")
      color: renderer.prop("check_color", Color.background)
      font.family: checkRoot.checkState === Qt.PartiallyChecked
        ? String(renderer.prop("font_family", renderer.fontFamily)) : renderer.iconFontFamily
      font.pixelSize: Math.max(10, parent.height * 0.62)
      font.bold: true
    }
  }

  onClicked: {
    var payload = eventPayload()
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", payload)
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "activate", payload)
  }
  onCheckStateChanged: {
    var payload = eventPayload()
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "toggle", payload)
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", payload)
  }
  onPressed: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "press", eventPayload())
  onReleased: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "release", eventPayload())
  onHoveredChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    "hover", { value: hovered })
  onActiveFocusChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    activeFocus ? "focus" : "blur", {})
  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
}
