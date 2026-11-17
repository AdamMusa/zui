import QtQuick
import QtLocation
import QtPositioning

MapPolyline {
  id: root
  required property var renderer
  function parentMap() { var item=root.parent;while(item){if(typeof item["addMapItem"]==="function")return item;item=item.parent}return null }
  function coordinates(values) { var result=[];values=values||[];for(var index=0;index<values.length;index++){var value=values[index]||{};result.push(QtPositioning.coordinate(Number(value.latitude||0),Number(value.longitude||0),Number(value.altitude||0)))}return result }
  path: coordinates(renderer.prop("path", []))
  line.color: renderer.prop("color", "#2563eb")
  line.width: Number(renderer.prop("width", 6))
  opacity: Number(renderer.prop("opacity", 1))
  visible: renderer.prop("visible", true) !== false
  TapHandler { onTapped: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", {}) }
  Component.onCompleted: { var map=parentMap();if(map)map.addMapItem(root) }
  Component.onDestruction: { var map=parentMap();if(map)map.removeMapItem(root) }
}
