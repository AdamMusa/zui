import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.SpinBox {
  id: nativeDoubleSpinBox
  required property var renderer

  readonly property int decimalPlaces: Math.max(0, Math.min(9,
    Number(renderer.prop("decimals", 2))))
  readonly property real scaleFactor: Math.pow(10, decimalPlaces)
  readonly property real realValue: value / scaleFactor

  from: Math.round(Number(renderer.prop("minimum", 0)) * scaleFactor)
  to: Math.round(Number(renderer.prop("maximum", 100)) * scaleFactor)
  value: Math.round(Number(renderer.prop("value", from / scaleFactor)) * scaleFactor)
  stepSize: Math.max(1, Math.round(Number(renderer.prop("step", 0.1)) * scaleFactor))
  editable: renderer.prop("editable", true) !== false
  wrap: renderer.prop("wrap", false) === true
  enabled: renderer.prop("enabled", true) !== false
  implicitWidth: Number(renderer.prop("width", 160))
  font.family: String(renderer.prop("font_family", renderer.fontFamily))
  font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
  palette.text: renderer.prop("foreground", renderer.foreground)
  palette.buttonText: renderer.prop("foreground", renderer.foreground)
  palette.button: renderer.prop("background", Color.popups.background)
  palette.highlight: renderer.prop("accent", Color.accent)

  textFromValue: function(scaledValue, locale) {
    return String(renderer.prop("prefix", ""))
      + Number(scaledValue / scaleFactor).toLocaleString(locale, "f", decimalPlaces)
      + String(renderer.prop("suffix", ""))
  }

  valueFromText: function(text, locale) {
    var prefix = String(renderer.prop("prefix", ""))
    var suffix = String(renderer.prop("suffix", ""))
    var numeric = String(text)
    if (prefix.length > 0 && numeric.indexOf(prefix) === 0)
      numeric = numeric.slice(prefix.length)
    if (suffix.length > 0 && numeric.lastIndexOf(suffix) === numeric.length - suffix.length)
      numeric = numeric.slice(0, -suffix.length)
    return Math.round(Number.fromLocaleString(locale, numeric) * scaleFactor)
  }

  onValueModified: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    "change", { value: realValue })
  up.onPressedChanged: {
    if (up.pressed)
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
        "increase", { value: realValue })
  }
  down.onPressedChanged: {
    if (down.pressed)
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
        "decrease", { value: realValue })
  }
}
