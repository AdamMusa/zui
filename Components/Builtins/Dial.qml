import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

QQC.Dial {
  required property var renderer
      id: nativeDial
      from: Number(renderer.prop("minimum", 0))
      to: Number(renderer.prop("maximum", 1))
      value: Number(renderer.prop("value", from))
      stepSize: Number(renderer.prop("step", 0))
      startAngle: Number(renderer.prop("start_angle", -140))
      endAngle: Number(renderer.prop("end_angle", 140))
      snapMode: {
        var mode = String(renderer.prop("snap", "none"))
        if (mode === "always") return QQC.Dial.SnapAlways
        if (mode === "release") return QQC.Dial.SnapOnRelease
        return QQC.Dial.NoSnap
      }
      wrap: renderer.prop("wrap", false) === true
      live: renderer.prop("live", true) !== false
      inputMode: {
        var mode = String(renderer.prop("input_mode", "circular"))
        if (mode === "horizontal") return QQC.Dial.Horizontal
        if (mode === "vertical") return QQC.Dial.Vertical
        return QQC.Dial.Circular
      }
      implicitWidth: Number(renderer.prop("size", 100))
      implicitHeight: implicitWidth
      palette.windowText: renderer.prop("foreground", renderer.foreground)
      palette.button: renderer.prop("background", Color.popups.background)
      palette.highlight: renderer.prop("accent", Color.accent)
      onMoved: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "input", { value: value, angle: angle })
      onPressedChanged: {
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, pressed ? "press" : "release", { value: value })
        if (!pressed) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: value })
      }
    }
