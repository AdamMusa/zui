import QtQuick

Item {
  id: shortcutRoot
  required property var renderer
  implicitWidth: 0
  implicitHeight: 0

  function shortcutContext() {
    var requested = String(renderer.prop("context", "window"))
    if (requested === "application") return Qt.ApplicationShortcut
    if (requested === "widget") return Qt.WidgetShortcut
    if (requested === "widget_with_children") return Qt.WidgetWithChildrenShortcut
    return Qt.WindowShortcut
  }

  function requestedSequences() {
    var many = renderer.prop("sequences", null)
    if (Array.isArray(many)) return many.map(String)
    var single = renderer.prop("sequence", "")
    return String(single) === "" ? [] : [String(single)]
  }

  function payload() {
    return {
      sequence: String(nativeShortcut.sequence),
      native_text: nativeShortcut.nativeText,
      portable_text: nativeShortcut.portableText
    }
  }

  Shortcut {
    id: nativeShortcut
    sequences: shortcutRoot.requestedSequences()
    enabled: renderer.prop("enabled", true) !== false
    autoRepeat: renderer.prop("auto_repeat", true) !== false
    context: shortcutRoot.shortcutContext()
    onActivated: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "activate", shortcutRoot.payload())
    onActivatedAmbiguously: {
      if (renderer.subscribed("ambiguous"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "ambiguous", shortcutRoot.payload())
    }
  }
}
