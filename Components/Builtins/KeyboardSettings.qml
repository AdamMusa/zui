import QtQuick
import QtQuick.VirtualKeyboard.Settings

Item {
  id: root
  required property var renderer
  visible: false

  function synchronize() {
    var style = String(renderer.prop("style", ""))
    var locale = String(renderer.prop("locale", ""))
    var locales = renderer.prop("active_locales", null)
    var dataPath = String(renderer.prop("user_data_path", ""))
    if (style !== "") VirtualKeyboardSettings.styleName = style
    if (locale !== "") VirtualKeyboardSettings.locale = locale
    if (Array.isArray(locales)) VirtualKeyboardSettings.activeLocales = locales
    if (dataPath !== "") VirtualKeyboardSettings.userDataPath = renderer.assetUrl(dataPath)
    VirtualKeyboardSettings.fullScreenMode = renderer.prop("full_screen_mode", false) === true
    VirtualKeyboardSettings.handwritingModeDisabled = renderer.prop("handwriting_disabled", false) === true
    VirtualKeyboardSettings.defaultInputMethodDisabled = renderer.prop("default_input_method_disabled", false) === true
    VirtualKeyboardSettings.defaultDictionaryDisabled = renderer.prop("default_dictionary_disabled", false) === true
    VirtualKeyboardSettings.closeOnReturn = renderer.prop("close_on_return", false) === true
    publish()
  }

  function publish() {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", {
      style: String(VirtualKeyboardSettings.styleName), locale: String(VirtualKeyboardSettings.locale),
      available_locales: VirtualKeyboardSettings.availableLocales.map(String),
      active_locales: VirtualKeyboardSettings.activeLocales.map(String),
      full_screen_mode: VirtualKeyboardSettings.fullScreenMode,
      handwriting_disabled: VirtualKeyboardSettings.handwritingModeDisabled
    })
  }

  Component.onCompleted: synchronize()
  Connections { target: renderer; function onNodeChanged() { root.synchronize() } }
  Connections {
    target: VirtualKeyboardSettings
    function onLocaleChanged() { root.publish() }
    function onActiveLocalesChanged() { root.publish() }
    function onStyleNameChanged() { root.publish() }
  }
}
