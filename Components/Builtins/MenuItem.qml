import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.MenuItem {
  id: itemRoot

  required property var renderer

  function payload(shortcutActivation) {
    return {
      label: text,
      value: renderer.prop("value", text),
      checked: checked,
      shortcut: shortcutActivation === true
    }
  }

  text: String(renderer.prop("text", ""))
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false
  checkable: renderer.prop("checkable", false) === true
  checked: renderer.prop("checked", false) === true
  highlighted: renderer.prop("highlighted", false) === true
  hoverEnabled: renderer.subscribed("hover") || renderer.subscribed("highlight")
  implicitWidth: Number(renderer.prop("width", 240))
  implicitHeight: Number(renderer.prop("height", 42))
  icon.name: String(renderer.prop("icon", ""))
  icon.source: String(renderer.prop("icon_source", ""))
  icon.color: renderer.prop("icon_color", highlighted
    ? renderer.prop("highlighted_foreground", renderer.prop("accent", Color.accent))
    : renderer.prop("foreground", renderer.foreground))
  font.family: String(renderer.prop("font_family", renderer.fontFamily))
  font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
  palette.buttonText: highlighted
    ? renderer.prop("highlighted_foreground", renderer.prop("accent", Color.accent))
    : (enabled ? renderer.prop("foreground", renderer.foreground)
      : renderer.prop("muted", Color.muted))

  background: Rectangle {
    color: itemRoot.highlighted
      ? renderer.prop("highlighted_background", renderer.prop("background", "transparent"))
      : renderer.prop("background", "transparent")
    radius: Number(renderer.prop("radius", Style.cornerRadius))
    border.width: String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0
    border.color: renderer.prop("border_color", "transparent")
  }

  Shortcut {
    sequence: String(renderer.prop("shortcut", ""))
    enabled: itemRoot.enabled && sequence.toString().length > 0
    onActivated: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "trigger", itemRoot.payload(true))
  }

  onClicked: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    "trigger", payload(false))
  onToggled: {
    var current = payload(false)
    if (renderer.subscribed("toggle"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "toggle", current)
    if (renderer.subscribed("change"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", current)
  }
  onPressed: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "press", payload(false))
  onReleased: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "release", payload(false))
  onHoveredChanged: {
    if (renderer.subscribed("hover"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", { value: hovered })
  }
  onHighlightedChanged: {
    if (renderer.subscribed("highlight"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "highlight", { value: highlighted })
  }
  onActiveFocusChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    activeFocus ? "focus" : "blur", {})
}
