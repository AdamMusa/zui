import QtQuick

Item {
  id: validatorRoot
  property var renderer: null
  property string handledRequestKey: ""
  implicitWidth: 0
  implicitHeight: 0

  function requestKey() {
    if (!renderer) return ""
    return [String(renderer.prop("text", "")), String(renderer.prop("bottom", -2147483648)),
      String(renderer.prop("top", 2147483647)), String(renderer.prop("locale", ""))].join("\u001f")
  }

  function evaluate() {
    if (!renderer) return
    var key = requestKey()
    if (key === handledRequestKey) return
    handledRequestKey = key
    nativeValidator.bottom = Number(renderer.prop("bottom", -2147483648))
    nativeValidator.top = Number(renderer.prop("top", 2147483647))
    nativeValidator.locale = String(renderer.prop("locale", Qt.locale().name))
    probe.text = String(renderer.prop("text", ""))
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "validate", {
      text: probe.text, valid: probe.acceptableInput, bottom: nativeValidator.bottom,
      top: nativeValidator.top, locale: nativeValidator.locale
    })
  }

  IntValidator { id: nativeValidator }

  TextInput {
    id: probe
    visible: false
    enabled: false
    width: 0
    height: 0
    validator: nativeValidator
  }

  Component.onCompleted: evaluate()
  Connections { target: renderer; function onNodeChanged() { validatorRoot.evaluate() } }
}
