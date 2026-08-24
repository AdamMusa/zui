import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

ZuiControls.PanelSlider {
  required property var renderer
      value: Number(renderer.prop("value", 0)); minimum: Number(renderer.prop("minimum", 0)); maximum: Number(renderer.prop("maximum", 1))
      step: Number(renderer.prop("step", 0.05)); integer: renderer.prop("integer", false) === true; tickCount: Number(renderer.prop("ticks", 0))
      implicitWidth: Number(renderer.prop("width", 200)); trackColor: renderer.prop("track_color", "#333")
      fillColor: renderer.prop("fill_color", renderer.foreground); knobColor: renderer.prop("knob_color", renderer.foreground)
      trackHeight: Number(renderer.prop("track_height", Math.max(4, Math.round(Style.spacing.controlHeight * 0.11))))
      knobSize: Number(renderer.prop("knob_size", Math.max(14, Math.round(Style.spacing.controlHeight * 0.38))))
      tickColor: renderer.prop("tick_color", Color.background)
      onReleased: function(value) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: value }) }
      onMoved: function(value) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "input", { value: value }) }
      onRightClicked: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "right_click", {})
    }
