import QtQuick

Item {
  id: screenRoot
  required property var renderer
  property int handledRefreshRevision: -1
  implicitWidth: 0
  implicitHeight: 0

  function orientationName(value) {
    if (value === Qt.PortraitOrientation) return "portrait"
    if (value === Qt.LandscapeOrientation) return "landscape"
    if (value === Qt.InvertedPortraitOrientation) return "inverted_portrait"
    if (value === Qt.InvertedLandscapeOrientation) return "inverted_landscape"
    return "primary"
  }

  function publish() {
    var screen = screenRoot.Screen
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "screen", {
      name: String(screen.name),
      manufacturer: String(screen.manufacturer),
      model: String(screen.model),
      serial_number: String(screen.serialNumber),
      width: screen.width, height: screen.height,
      desktop_available_width: screen.desktopAvailableWidth,
      desktop_available_height: screen.desktopAvailableHeight,
      logical_pixel_density: screen.logicalPixelDensity,
      pixel_density: screen.pixelDensity,
      device_pixel_ratio: screen.devicePixelRatio,
      primary_orientation: screenRoot.orientationName(screen.primaryOrientation),
      orientation: screenRoot.orientationName(screen.orientation),
      virtual_x: screen.virtualX, virtual_y: screen.virtualY
    })
  }

  function refresh() {
    var revision = Number(renderer.prop("refresh_revision", 0))
    if (revision === handledRefreshRevision) return
    handledRefreshRevision = revision
    publish()
  }

  Component.onCompleted: refresh()
  Connections { target: renderer; function onNodeChanged() { screenRoot.refresh() } }
  Connections {
    target: screenRoot.Screen
    enabled: renderer.prop("watch", true) !== false
    function onOrientationChanged() { screenRoot.publish() }
    function onWidthChanged() { screenRoot.publish() }
    function onHeightChanged() { screenRoot.publish() }
    function onDevicePixelRatioChanged() { screenRoot.publish() }
  }
}
