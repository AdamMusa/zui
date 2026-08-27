import QtQuick
import QtLocation
import QtPositioning

Item {
  id: root
  required property var renderer
  property var parameterObjects: []
  property int handledCommandRevision: -1
  property string pendingOperation: "details"
  visible: false

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

  function visibilityValue() {
    var value = String(renderer.prop("visibility", "unspecified"))
    if (value === "device") return Place.DeviceVisibility
    if (value === "private") return Place.PrivateVisibility
    if (value === "public") return Place.PublicVisibility
    return Place.UnspecifiedVisibility
  }

  function statusName(value) { return ["ready", "saving", "fetching", "removing", "error"][Number(value)] || "unknown" }

  function publish(eventName) {
    var coordinate = nativePlace.location.coordinate
    var address = nativePlace.location.address
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, eventName, {
      place_id: String(nativePlace.placeId), name: String(nativePlace.name), attribution: String(nativePlace.attribution),
      latitude: coordinate.latitude, longitude: coordinate.longitude, altitude: coordinate.altitude,
      address: { text: String(address.text), country: String(address.country), country_code: String(address.countryCode),
        state: String(address.state), county: String(address.county), city: String(address.city), district: String(address.district),
        street: String(address.street), postal_code: String(address.postalCode) }, phone: String(nativePlace.primaryPhone),
      fax: String(nativePlace.primaryFax), email: String(nativePlace.primaryEmail), website: String(nativePlace.primaryWebsite),
      details_fetched: nativePlace.detailsFetched
    })
  }

  function processCommand() {
    var revision = Number(renderer.prop("command_revision", 0))
    if (revision === handledCommandRevision) return
    var first = handledCommandRevision < 0
    handledCommandRevision = revision
    if (first && revision <= 0) return
    var command = String(renderer.prop("command", "details"))
    pendingOperation = command
    if (command === "save") nativePlace.save()
    else if (command === "remove") nativePlace.remove()
    else nativePlace.getDetails()
  }

  Component { id: parameterComponent; PluginParameter {} }
  Plugin { id: nativePlugin }
  Location {
    id: nativeLocation
    coordinate: QtPositioning.coordinate(Number(root.renderer.prop("latitude", 0)),
      Number(root.renderer.prop("longitude", 0)), Number(root.renderer.prop("altitude", 0)))
  }
  Place {
    id: nativePlace
    plugin: nativePlugin
    placeId: String(root.renderer.prop("place_id", ""))
    name: String(root.renderer.prop("name", ""))
    attribution: String(root.renderer.prop("attribution", ""))
    visibility: root.visibilityValue()
    location: nativeLocation
    onStatusChanged: {
      var name = root.statusName(status)
      root.renderer.bridge.sendEvent(root.renderer.surfaceName, root.renderer.controlId, "status", { value: name })
      if (name === "ready") {
        var eventName = root.pendingOperation === "remove" ? "removed"
          : (root.pendingOperation === "save" ? "saved" : "details")
        root.publish(eventName)
      }
      else if (name === "error") root.renderer.componentError("place_operation_failed", errorString(), {})
    }
  }
  Component.onCompleted: { configurePlugin(); publish("details"); processCommand() }
  Connections { target: renderer; function onNodeChanged() { root.configurePlugin(); root.processCommand() } }
}
