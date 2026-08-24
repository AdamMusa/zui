import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

ZuiControls.NumberField {
  required property var renderer
      label: renderer.escapeAutoText(renderer.prop("label", "")); value: Number(renderer.prop("value", 0))
      from: Number(renderer.prop("from", 0)); to: Number(renderer.prop("to", 100)); stepSize: Number(renderer.prop("step", 1))
      foreground: renderer.prop("foreground", renderer.foreground); accent: renderer.prop("accent", Color.accent)
      fontFamily: String(renderer.prop("font_family", renderer.fontFamily)); fontSize: Number(renderer.prop("font_size", Style.font.body))
      fieldWidth: Number(renderer.prop("field_width", Style.spacing.numberFieldWidth)); hasCursor: renderer.prop("cursor", false) === true
      onModified: function(value) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: value }) }
      onHovered: function(value) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", { value: value }) }
    }
