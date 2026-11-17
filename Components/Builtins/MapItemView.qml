import QtQuick
import QtLocation
import QtPositioning

MapItemView {
  id: root
  required property var renderer
  function parentMap() { var item=root.parent;while(item){if(typeof item["addMapItemView"]==="function")return item;item=item.parent}return null }
  model: renderer.prop("items", []) || []
  delegate: MapQuickItem {
    required property int index
    required property var modelData
    readonly property string latitudeField: String(renderer.prop("latitude_field", "latitude"))
    readonly property string longitudeField: String(renderer.prop("longitude_field", "longitude"))
    coordinate: QtPositioning.coordinate(Number(modelData[latitudeField] || 0), Number(modelData[longitudeField] || 0))
    anchorPoint.x: sourceItem.width / 2; anchorPoint.y: sourceItem.height
    sourceItem: Rectangle {
      width: Number(renderer.prop("marker_width", 28)); height: Number(renderer.prop("marker_height", 28)); radius: width / 2
      color: renderer.prop("marker_color", "#3b82f6")
      Text { anchors.centerIn: parent; text: String(modelData[String(renderer.prop("label_field", "label"))] || ""); color: "white" }
      TapHandler { onTapped: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", { index: index, value: modelData }) }
    }
  }
  Component.onCompleted: { var map=parentMap();if(map)map.addMapItemView(root) }
  Component.onDestruction: { var map=parentMap();if(map)map.removeMapItemView(root) }
}
