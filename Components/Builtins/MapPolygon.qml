import QtQuick
import QtLocation
import QtPositioning

MapPolygon {
  id: root
  required property var renderer
  function parentMap() { var item=root.parent;while(item){if(typeof item["addMapItem"]==="function")return item;item=item.parent}return null }
  function coordinates(values) { var result=[];values=values||[];for(var index=0;index<values.length;index++){var value=values[index]||{};result.push(QtPositioning.coordinate(Number(value.latitude||0),Number(value.longitude||0),Number(value.altitude||0)))}return result }
  path: coordinates(renderer.prop("path", []))
  color: renderer.prop("color", "#403b82f6")
  border.color: renderer.prop("border_color", "#3b82f6")
  border.width: Number(renderer.prop("border_width", 2))
  opacity: Number(renderer.prop("opacity", 1))
  visible: renderer.prop("visible", true) !== false
  TapHandler { onTapped: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", {}) }
  Component.onCompleted: { var map=parentMap();if(map)map.addMapItem(root) }
  Component.onDestruction: { var map=parentMap();if(map)map.removeMapItem(root) }
}
