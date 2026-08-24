import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

QQC.SpinBox {
  required property var renderer
      id: nativeSpinBox
      from: Number(renderer.prop("minimum", 0))
      to: Number(renderer.prop("maximum", 100))
      value: Number(renderer.prop("value", from))
      stepSize: Number(renderer.prop("step", 1))
      editable: renderer.prop("editable", true) !== false
      wrap: renderer.prop("wrap", false) === true
      enabled: renderer.prop("enabled", true) !== false
      implicitWidth: Number(renderer.prop("width", 140))
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
      palette.text: renderer.prop("foreground", renderer.foreground)
      palette.buttonText: renderer.prop("foreground", renderer.foreground)
      palette.button: renderer.prop("background", Color.popups.background)
      palette.highlight: renderer.prop("accent", Color.accent)
      textFromValue: function(value, locale) {
        return String(renderer.prop("prefix", "")) + Number(value).toLocaleString(locale, "f", 0) + String(renderer.prop("suffix", ""))
      }
      valueFromText: function(text, locale) {
        var prefix = String(renderer.prop("prefix", ""))
        var suffix = String(renderer.prop("suffix", ""))
        var numeric = String(text)
        if (prefix.length > 0 && numeric.indexOf(prefix) === 0) numeric = numeric.slice(prefix.length)
        if (suffix.length > 0 && numeric.lastIndexOf(suffix) === numeric.length - suffix.length) numeric = numeric.slice(0, -suffix.length)
        return Number.fromLocaleString(locale, numeric)
      }
      onValueModified: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: value })
      up.onPressedChanged: {
        if (up.pressed) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "increase", { value: value })
      }
      down.onPressedChanged: {
        if (down.pressed) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "decrease", { value: value })
      }
    }
