import QtQuick
import QtLocation
import QtPositioning

MapQuickItem {
  id: root
  required property var renderer
  function parentMap() { var item=root.parent;while(item){if(typeof item["addMapItem"]==="function")return item;item=item.parent}return null }
  implicitWidth: Number(renderer.prop("width", sourceHost.childrenRect.width || 44))
  implicitHeight: Number(renderer.prop("height", sourceHost.childrenRect.height || 44))
  coordinate: QtPositioning.coordinate(Number(renderer.prop("latitude", 0)), Number(renderer.prop("longitude", 0)), Number(renderer.prop("altitude", 0)))
  anchorPoint.x: Number(renderer.prop("anchor_x", implicitWidth / 2))
  anchorPoint.y: Number(renderer.prop("anchor_y", implicitHeight))
  zoomLevel: Number(renderer.prop("zoom_level", 0))
  autoFadeIn: renderer.prop("auto_fade_in", true) !== false
  visible: renderer.prop("visible", true) !== false
  sourceItem: Item {
    id: sourceHost
    width: root.implicitWidth; height: root.implicitHeight
    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
    TapHandler { onTapped: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", { latitude: root.coordinate.latitude, longitude: root.coordinate.longitude }) }
    DragHandler {
      target: null
      onTranslationChanged: { var map=root.parentMap();if(!map)return;var point=map.mapFromItem(sourceHost,centroid.position.x,centroid.position.y);var next=map.toCoordinate(point);renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"drag",{latitude:next.latitude,longitude:next.longitude}) }
    }
  }
  Component.onCompleted: { var map=parentMap();if(map)map.addMapItem(root) }
  Component.onDestruction: { var map=parentMap();if(map)map.removeMapItem(root) }
}
