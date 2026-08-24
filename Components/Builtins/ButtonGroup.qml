import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

ZuiControls.ButtonGroup {
  required property var renderer
      value: String(renderer.prop("value", "")); options: renderer.prop("options", [])
      foreground: renderer.prop("foreground", renderer.foreground); background: renderer.prop("background", Color.background)
      accent: renderer.prop("accent", Color.accent); fontFamily: String(renderer.prop("font_family", renderer.fontFamily))
      fontSize: Number(renderer.prop("font_size", Style.font.body)); focusable: renderer.prop("focusable", true) !== false
      cursorIndex: Number(renderer.prop("cursor_index", -1))
      onChanged: function(value) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: value }) }
      onHovered: function(index, value) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", { index: index, value: value }) }
    }
