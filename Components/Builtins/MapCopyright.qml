import QtQuick
import QtLocation

MapCopyrightNotice {
  id: root
  required property var renderer

  function parentMap() {
    var item = root.parent
    while (item) {
      if (typeof item["pan"] === "function" && item.supportedMapTypes !== undefined) return item
      item = item.parent
    }
    return null
  }

  mapSource: parentMap()
  styleSheet: String(renderer.prop("style_sheet", ""))
  implicitWidth: Number(renderer.prop("width", 240))
  implicitHeight: Number(renderer.prop("height", 40))
  visible: renderer.prop("visible", true) !== false
  onLinkActivated: function(link) {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "link", { url: String(link) })
  }
}
