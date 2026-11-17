import QtQuick
import QtLocation
import QtPositioning

MapCircle {
  id: root
  required property var renderer
  function parentMap() { var item=root.parent;while(item){if(typeof item["addMapItem"]==="function")return item;item=item.parent}return null }
  center: QtPositioning.coordinate(Number(renderer.prop("latitude", 0)), Number(renderer.prop("longitude", 0)), Number(renderer.prop("altitude", 0)))
  radius: Number(renderer.prop("radius", 100))
  color: renderer.prop("color", "#403b82f6")
  border.color: renderer.prop("border_color", "#3b82f6")
  border.width: Number(renderer.prop("border_width", 2))
  opacity: Number(renderer.prop("opacity", 1))
  visible: renderer.prop("visible", true) !== false
  TapHandler { onTapped: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", { latitude: root.center.latitude, longitude: root.center.longitude }) }
  Component.onCompleted: { var map=parentMap();if(map)map.addMapItem(root) }
  Component.onDestruction: { var map=parentMap();if(map)map.removeMapItem(root) }
}
