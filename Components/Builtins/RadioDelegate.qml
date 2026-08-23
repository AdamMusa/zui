import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"

QQC.RadioDelegate {
  id: radioRoot

  required property var renderer
  readonly property bool selected: renderer.prop("selected", false) === true
  readonly property real indicatorSize: Number(renderer.prop("indicator_size", 22))

  function eventPayload() {
    return {
      text: text,
      value: renderer.prop("value", text),
      checked: checked,
      selected: selected
    }
  }

  text: String(renderer.prop("text", ""))
  checked: renderer.prop("checked", false) === true
  autoExclusive: renderer.prop("auto_exclusive", true) !== false
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
    color: radioRoot.highlighted
      ? renderer.prop("highlighted_background", renderer.prop("selected_background", Color.popups.background))
      : (radioRoot.selected
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
      text: radioRoot.text
      textFormat: Text.PlainText
      color: radioRoot.selected
        ? renderer.prop("selected_foreground", renderer.prop("foreground", renderer.foreground))
        : renderer.prop("foreground", renderer.foreground)
      font: radioRoot.font
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
    x: radioRoot.width - radioRoot.rightPadding + Number(renderer.prop("spacing", Style.spacing.md))
    y: (radioRoot.height - height) / 2
    width: radioRoot.indicatorSize
    height: radioRoot.indicatorSize
    radius: width / 2
    color: renderer.prop("indicator_background", "transparent")
    border.width: Style.normalBorderWidth
    border.color: renderer.prop("indicator_border",
      radioRoot.checked ? renderer.prop("accent", Color.accent) : renderer.foreground)

    Rectangle {
      anchors.centerIn: parent
      width: Number(renderer.prop("dot_size", Math.max(8, parent.width * 0.48)))
      height: width
      radius: width / 2
      visible: radioRoot.checked
      color: renderer.prop("dot_color", renderer.prop("accent", Color.accent))
    }
  }

  onClicked: {
    var payload = eventPayload()
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", payload)
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "activate", payload)
    if (checked) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "select", payload)
  }
  onToggled: {
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
