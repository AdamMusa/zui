import QtQuick

Item {
  id: paletteRoot
  required property var renderer
  property string handledRequestKey: ""
  implicitWidth: 0
  implicitHeight: 0

  function colorGroup() {
    var requested = String(renderer.prop("color_group", "active"))
    if (requested === "inactive") return SystemPalette.Inactive
    if (requested === "disabled") return SystemPalette.Disabled
    return SystemPalette.Active
  }

  function republishOnRequestChange() {
    var key = String(renderer.prop("color_group", "active"))
    if (key === handledRequestKey) return
    handledRequestKey = key
    publish()
  }

  function publish() {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "palette", {
      color_group: String(renderer.prop("color_group", "active")),
      window: String(nativePalette.window), window_text: String(nativePalette.windowText),
      base: String(nativePalette.base), alternate_base: String(nativePalette.alternateBase),
      text: String(nativePalette.text),
      button: String(nativePalette.button), button_text: String(nativePalette.buttonText),
      light: String(nativePalette.light), midlight: String(nativePalette.midlight),
      mid: String(nativePalette.mid), dark: String(nativePalette.dark),
      shadow: String(nativePalette.shadow),
      highlight: String(nativePalette.highlight),
      highlighted_text: String(nativePalette.highlightedText),
      placeholder_text: String(nativePalette.placeholderText),
      accent: String(nativePalette.accent)
    })
  }

  SystemPalette {
    id: nativePalette
    colorGroup: paletteRoot.colorGroup()
    onPaletteChanged: paletteRoot.publish()
  }

  Component.onCompleted: republishOnRequestChange()
  Connections { target: renderer; function onNodeChanged() { paletteRoot.republishOnRequestChange() } }
}
