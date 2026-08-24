import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

QQC.RangeSlider {
  required property var renderer
      id: nativeRangeSlider
      from: Number(renderer.prop("minimum", 0))
      to: Number(renderer.prop("maximum", 1))
      stepSize: Number(renderer.prop("step", 0))
      first.value: Number(renderer.prop("lower", from))
      second.value: Number(renderer.prop("upper", to))
      orientation: String(renderer.prop("orientation", "horizontal")) === "vertical" ? Qt.Vertical : Qt.Horizontal
      snapMode: {
        var mode = String(renderer.prop("snap", "none"))
        if (mode === "always") return QQC.RangeSlider.SnapAlways
        if (mode === "release") return QQC.RangeSlider.SnapOnRelease
        return QQC.RangeSlider.NoSnap
      }
      live: renderer.prop("live", true) !== false
      implicitWidth: Number(renderer.prop("width", orientation === Qt.Horizontal ? 240 : 40))
      implicitHeight: Number(renderer.prop("height", orientation === Qt.Horizontal ? 40 : 240))
      palette.windowText: renderer.prop("foreground", renderer.foreground)
      palette.button: renderer.prop("background", Color.popups.background)
      palette.highlight: renderer.prop("accent", Color.accent)
      function payload() { return { lower: first.value, upper: second.value } }
      first.onMoved: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "input", payload())
      second.onMoved: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "input", payload())
      first.onPressedChanged: {
        if (!first.pressed) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", payload())
      }
      second.onPressedChanged: {
        if (!second.pressed) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", payload())
      }
    }
