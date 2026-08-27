import QtQuick
import QtLocation
import QtPositioning

Map {
  id: root
  required property var renderer
  property var parameterObjects: []
  function coordinate(latitude, longitude, altitude) {
    return QtPositioning.coordinate(Number(latitude), Number(longitude), Number(altitude || 0))
  }
  function configurePlugin() {
    for (var oldIndex = 0; oldIndex < parameterObjects.length; oldIndex++) parameterObjects[oldIndex].destroy()
    var objects = []
    var values = renderer.prop("plugin_parameters", {}) || {}
    var names = Object.keys(values).sort()
    for (var index = 0; index < names.length; index++)
      objects.push(parameterComponent.createObject(root, { name: names[index], value: values[names[index]] }))
    parameterObjects = objects
    nativePlugin.parameters = objects
    nativePlugin.name = String(renderer.prop("plugin", "osm"))
  }
  function selectMapType() {
    var requested = String(renderer.prop("map_type", "street")).toLowerCase()
    for (var index = 0; index < supportedMapTypes.length; index++) {
      var candidate = supportedMapTypes[index]
      if (String(candidate.name).toLowerCase().indexOf(requested) >= 0 || String(candidate.description).toLowerCase().indexOf(requested) >= 0) {
        activeMapType = candidate
        return
      }
    }
  }
  function send(name, payload) {
    if (renderer.subscribed(name)) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }
  implicitWidth: Number(renderer.prop("width", 640))
  implicitHeight: Number(renderer.prop("height", 420))
  visible: renderer.prop("visible", true) !== false
  plugin: nativePlugin
  center: coordinate(renderer.prop("latitude", 0), renderer.prop("longitude", 0), renderer.prop("altitude", 0))
  zoomLevel: Number(renderer.prop("zoom", 12))
  minimumZoomLevel: Number(renderer.prop("minimum_zoom", 1))
  maximumZoomLevel: Number(renderer.prop("maximum_zoom", 22))
  bearing: Number(renderer.prop("bearing", 0))
  tilt: Number(renderer.prop("tilt", 0))
  fieldOfView: Number(renderer.prop("field_of_view", 45))
  copyrightsVisible: renderer.prop("copyrights_visible", true) !== false
  Component { id: parameterComponent; PluginParameter {} }
  Plugin { id: nativePlugin }
  Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  MapItemView {
    model: renderer.prop("markers", []) || []
    delegate: MapQuickItem {
      required property var modelData
      coordinate: root.coordinate(modelData.latitude, modelData.longitude, modelData.altitude)
      anchorPoint.x: sourceItem.width / 2
      anchorPoint.y: sourceItem.height
      sourceItem: Rectangle { width: Number(modelData.width || 24); height: width; radius: width / 2; color: modelData.color || "#3b82f6"; border.color: modelData.border_color || "white" }
    }
  }
  DragHandler {
    id: panHandler
    target: null
    enabled: renderer.prop("gesture_enabled", true) !== false
    property point previousTranslation: Qt.point(0, 0)
    onActiveChanged: previousTranslation = translation
    onTranslationChanged: {
      root.pan(-(translation.x - previousTranslation.x), -(translation.y - previousTranslation.y))
      previousTranslation = translation
    }
  }
  PinchHandler {
    id: zoomHandler
    target: null
    enabled: renderer.prop("gesture_enabled", true) !== false
    property real previousScale: 1
    onActiveChanged: previousScale = activeScale
    onActiveScaleChanged: {
      root.zoomLevel += Math.log(activeScale / previousScale) / Math.log(2)
      previousScale = activeScale
    }
  }
  WheelHandler {
    enabled: renderer.prop("gesture_enabled", true) !== false
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: function(event) { root.zoomLevel += event.angleDelta.y / 480; event.accepted = true }
  }
  TapHandler {
    id: mapTap
    acceptedButtons: Qt.LeftButton
    onTapped: function(point) { var value = root.toCoordinate(point.position); root.send("tap", { x: point.position.x, y: point.position.y, latitude: value.latitude, longitude: value.longitude }) }
    onLongPressed: { var value = root.toCoordinate(mapTap.point.position); root.send("long_press", { x: mapTap.point.position.x, y: mapTap.point.position.y, latitude: value.latitude, longitude: value.longitude }) }
  }
  onCenterChanged: send("center_change", { latitude: center.latitude, longitude: center.longitude, altitude: center.altitude })
  onZoomLevelChanged: send("zoom_change", { value: zoomLevel })
  onActiveMapTypeChanged: send("map_type_change", { name: activeMapType ? activeMapType.name : "" })
  onCopyrightLinkActivated: function(link) { send("copyright", { url: String(link) }) }
  onErrorChanged: if (Number(error) !== 0) renderer.componentError("map_failed", errorString, { native_code: Number(error) })
  onSupportedMapTypesChanged: selectMapType()
  Component.onCompleted: { configurePlugin(); selectMapType() }
  Connections { target: renderer; function onNodeChanged() { root.configurePlugin(); root.selectMapType() } }
}
