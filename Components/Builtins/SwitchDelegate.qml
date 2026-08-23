import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"

QQC.SwitchDelegate {
  id: switchRoot

  required property var renderer
  readonly property bool selected: renderer.prop("selected", false) === true
  readonly property real indicatorWidth: Number(renderer.prop("indicator_width", 44))
  readonly property real indicatorHeight: Number(renderer.prop("indicator_height", 24))

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
  highlighted: renderer.prop("highlighted", selected) === true
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false
  hoverEnabled: true
  implicitWidth: Number(renderer.prop("width", 320))
  implicitHeight: Number(renderer.prop("height", 56))
  padding: Number(renderer.prop("padding", Style.spacing.md))
  rightPadding: padding + indicatorWidth + Number(renderer.prop("spacing", Style.spacing.md))
  font.family: String(renderer.prop("font_family", renderer.fontFamily))
  font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
  Accessible.name: String(renderer.prop("accessible_name", text))

  background: Rectangle {
    color: switchRoot.highlighted
      ? renderer.prop("highlighted_background", renderer.prop("selected_background", Color.popups.background))
      : (switchRoot.selected
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
      text: switchRoot.text
      textFormat: Text.PlainText
      color: switchRoot.selected
        ? renderer.prop("selected_foreground", renderer.prop("foreground", renderer.foreground))
        : renderer.prop("foreground", renderer.foreground)
      font: switchRoot.font
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
    x: switchRoot.width - switchRoot.rightPadding + Number(renderer.prop("spacing", Style.spacing.md))
    y: (switchRoot.height - height) / 2
    width: switchRoot.indicatorWidth
    height: switchRoot.indicatorHeight
    radius: height / 2
    color: switchRoot.checked
      ? renderer.prop("checked_track_color", renderer.prop("accent", Color.accent))
      : renderer.prop("track_color", Qt.rgba(renderer.foreground.r,
          renderer.foreground.g, renderer.foreground.b, 0.24))
    border.width: Style.normalBorderWidth
    border.color: switchRoot.checked
      ? renderer.prop("checked_track_color", renderer.prop("accent", Color.accent))
      : renderer.prop("track_color", renderer.foreground)

    Behavior on color {
      enabled: renderer.prop("animated", true) !== false
      ColorAnimation { duration: Number(renderer.prop("duration", 140)) }
    }

    Rectangle {
      id: switchThumb
      readonly property real thumbSize: Math.min(parent.height - 4,
        Number(renderer.prop("thumb_size", parent.height - 4)))
      x: switchRoot.checked ? parent.width - width - 2 : 2
      y: (parent.height - height) / 2
      width: thumbSize
      height: thumbSize
      radius: width / 2
      color: switchRoot.checked
        ? renderer.prop("checked_thumb_color", Color.background)
        : renderer.prop("thumb_color", renderer.foreground)

      Behavior on x {
        enabled: renderer.prop("animated", true) !== false
        NumberAnimation {
          duration: Number(renderer.prop("duration", 140))
          easing.type: Easing.OutCubic
        }
      }
      Behavior on color {
        enabled: renderer.prop("animated", true) !== false
        ColorAnimation { duration: Number(renderer.prop("duration", 140)) }
      }
    }
  }

  onClicked: {
    var payload = eventPayload()
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", payload)
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "activate", payload)
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
