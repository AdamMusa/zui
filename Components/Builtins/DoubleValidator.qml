import QtQuick

Item {
  id: validatorRoot
  property var renderer: null
  property string handledRequestKey: ""
  implicitWidth: 0
  implicitHeight: 0

  function notationMode() {
    return String(renderer.prop("notation", "scientific")) === "standard"
      ? DoubleValidator.StandardNotation
      : DoubleValidator.ScientificNotation
  }

  function requestKey() {
    if (!renderer) return ""
    return [String(renderer.prop("text", "")), String(renderer.prop("bottom", -Number.MAX_VALUE)),
      String(renderer.prop("top", Number.MAX_VALUE)), String(renderer.prop("decimals", 1000)),
      String(renderer.prop("notation", "scientific")), String(renderer.prop("locale", ""))].join("\u001f")
  }

  function evaluate() {
    if (!renderer) return
    var key = requestKey()
    if (key === handledRequestKey) return
    handledRequestKey = key
    nativeValidator.bottom = Number(renderer.prop("bottom", -Number.MAX_VALUE))
    nativeValidator.top = Number(renderer.prop("top", Number.MAX_VALUE))
    nativeValidator.decimals = Number(renderer.prop("decimals", 1000))
    nativeValidator.notation = notationMode()
    nativeValidator.locale = String(renderer.prop("locale", Qt.locale().name))
    probe.text = String(renderer.prop("text", ""))
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "validate", {
      text: probe.text, valid: probe.acceptableInput, bottom: nativeValidator.bottom,
      top: nativeValidator.top, decimals: nativeValidator.decimals,
      notation: nativeValidator.notation === DoubleValidator.StandardNotation ? "standard" : "scientific",
      locale: nativeValidator.locale
    })
  }

  DoubleValidator { id: nativeValidator }

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
