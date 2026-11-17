import QtQuick
import QtLocation

MapItemGroup {
  id: root
  required property var renderer
  function parentMap() { var item=root.parent;while(item){if(typeof item["addMapItemGroup"]==="function")return item;item=item.parent}return null }
  visible: renderer.prop("visible", true) !== false
  Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  TapHandler { onTapped: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", {}) }
  Component.onCompleted: { var map=parentMap();if(map)map.addMapItemGroup(root) }
  Component.onDestruction: { var map=parentMap();if(map)map.removeMapItemGroup(root) }
}
