import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

ZuiControls.ToggleSwitch {
  required property var renderer
      checked: renderer.prop("checked", false) === true; busy: renderer.prop("busy", false) === true
      interactive: renderer.prop("interactive", renderer.prop("enabled", true)) !== false
      hasCursor: renderer.prop("cursor", false) === true; cursorRing: renderer.prop("cursor_ring", true) !== false
      cursorPad: Number(renderer.prop("cursor_pad", Style.space(6))); rounded: renderer.prop("rounded", Style.cornerRadius > 0) === true
      foreground: renderer.prop("foreground", renderer.foreground); accent: renderer.prop("accent", Color.accent)
      trackHeight: Number(renderer.prop("track_height", Math.max(22, Math.round(Style.spacing.controlHeight * 0.55))))
      trackWidth: Number(renderer.prop("track_width", Math.round(trackHeight * 1.9)))
      knobSize: Number(renderer.prop("knob_size", Math.max(6, Math.round(trackHeight * 0.72))))
      knobInset: Number(renderer.prop("knob_inset", Math.max(1, Math.round((trackHeight - knobSize) / 2))))
      onToggled: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: !checked })
      onHovered: function(value) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", { value: value }) }
    }
