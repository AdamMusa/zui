import QtQuick
import QtPositioning

Item {
  id: root
  required property var renderer
  readonly property alias location: nativeLocation
  property int handledRefreshRevision: -1
  visible: false

  function boundingShapePayload() {
    var shape = nativeLocation.boundingShape
    if (!shape || !shape.isValid) return { valid: false }
    var box = shape.boundingGeoRectangle()
    return {
      valid: true, type: Number(shape.type),
      top_left: { latitude: box.topLeft.latitude, longitude: box.topLeft.longitude },
      bottom_right: { latitude: box.bottomRight.latitude, longitude: box.bottomRight.longitude },
      center: { latitude: box.center.latitude, longitude: box.center.longitude },
      width: Number(box.width), height: Number(box.height)
    }
  }
  function publish() {
    var coordinate = nativeLocation.coordinate
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", {
      latitude: coordinate.latitude, longitude: coordinate.longitude, altitude: coordinate.altitude,
      valid: coordinate.isValid === true,
      address: {
        text: String(nativeAddress.text), country: String(nativeAddress.country),
        country_code: String(nativeAddress.countryCode), state: String(nativeAddress.state),
        county: String(nativeAddress.county), city: String(nativeAddress.city),
        district: String(nativeAddress.district), street: String(nativeAddress.street),
        street_number: String(nativeAddress.streetNumber), postal_code: String(nativeAddress.postalCode)
      },
      bounding_shape: boundingShapePayload(),
      extended_attributes: nativeLocation.extendedAttributes || {}
    })
  }
  function refresh() {
    var revision = Number(renderer.prop("refresh_revision", 0))
    if (revision === handledRefreshRevision) return
    handledRefreshRevision = revision
    publish()
  }

  Address {
    id: nativeAddress
    country: String(root.renderer.prop("country", ""))
    countryCode: String(root.renderer.prop("country_code", ""))
    state: String(root.renderer.prop("state", ""))
    county: String(root.renderer.prop("county", ""))
    city: String(root.renderer.prop("city", ""))
    district: String(root.renderer.prop("district", ""))
    street: String(root.renderer.prop("street", ""))
    streetNumber: String(root.renderer.prop("street_number", ""))
    postalCode: String(root.renderer.prop("postal_code", ""))
  }
  Binding {
    target: nativeAddress
    property: "text"
    value: String(root.renderer.prop("address", ""))
    when: String(root.renderer.prop("address", "")) !== ""
  }
  Location {
    id: nativeLocation
    address: nativeAddress
    coordinate: QtPositioning.coordinate(Number(root.renderer.prop("latitude", 0)),
                                         Number(root.renderer.prop("longitude", 0)),
                                         Number(root.renderer.prop("altitude", 0)))
    boundingShape: QtPositioning.rectangle(nativeLocation.coordinate,
                                           Number(root.renderer.prop("bounding_width", 0)),
                                           Number(root.renderer.prop("bounding_height", 0)))
    extendedAttributes: root.renderer.prop("extended_attributes", {}) || {}
    onCoordinateChanged: root.publish()
  }
  Connections { target: renderer; function onNodeChanged() { root.refresh() } }
  Component.onCompleted: refresh()
}
