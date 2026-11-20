import QtQuick
import QtPositioning

Item {
  id: root
  required property var renderer
  readonly property alias address: nativeAddress
  property int handledRefreshRevision: -1
  visible: false

  function publish() {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", {
      text: String(nativeAddress.text),
      country: String(nativeAddress.country),
      country_code: String(nativeAddress.countryCode),
      state: String(nativeAddress.state),
      county: String(nativeAddress.county),
      city: String(nativeAddress.city),
      district: String(nativeAddress.district),
      street: String(nativeAddress.street),
      street_number: String(nativeAddress.streetNumber),
      postal_code: String(nativeAddress.postalCode),
      text_generated: nativeAddress.isTextGenerated === true
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
    onTextChanged: root.publish()
    onIsTextGeneratedChanged: root.publish()
  }
  // Writing text switches Address off its generated single-line form, so only an explicit
  // text wins; an empty one leaves QGeoAddress generating the label from the fields above.
  Binding {
    target: nativeAddress
    property: "text"
    value: String(root.renderer.prop("text", ""))
    when: String(root.renderer.prop("text", "")) !== ""
  }
  Connections { target: renderer; function onNodeChanged() { root.refresh() } }
  Component.onCompleted: refresh()
}
