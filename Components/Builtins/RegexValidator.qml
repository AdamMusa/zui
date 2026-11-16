import QtQuick

Item {
  id: validatorRoot
  property var renderer: null
  property string handledRequestKey: ""
  implicitWidth: 0
  implicitHeight: 0

  function expressionFlags() {
    var flags = ""
    if (renderer.prop("case_insensitive", false) === true) flags += "i"
    if (renderer.prop("multiline", false) === true) flags += "m"
    if (renderer.prop("dot_matches_newline", false) === true) flags += "s"
    return flags
  }

  function requestKey() {
    if (!renderer) return ""
    return [String(renderer.prop("text", "")), String(renderer.prop("pattern", "")),
      String(renderer.prop("case_insensitive", false)), String(renderer.prop("multiline", false)),
      String(renderer.prop("dot_matches_newline", false))].join("\u001f")
  }

  function evaluate() {
    if (!renderer) return
    var key = requestKey()
    if (key === handledRequestKey) return
    handledRequestKey = key
    var pattern = String(renderer.prop("pattern", ""))
    var flags = expressionFlags()
    nativeValidator.regularExpression = new RegExp(pattern, flags)
    probe.text = String(renderer.prop("text", ""))
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "validate", {
      text: probe.text, valid: probe.acceptableInput, pattern: pattern, flags: flags
    })
  }

  RegularExpressionValidator { id: nativeValidator }

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
