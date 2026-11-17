import QtQuick
import QtLocation
import QtPositioning

Item {
  id: root
  required property var renderer
  property var parameterObjects: []
  property int handledCommandRevision: -1
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

  function searchArea() {
    var area = renderer.prop("search_area", null)
    if (!area || area.latitude === undefined) return QtPositioning.shape()
    return QtPositioning.circle(QtPositioning.coordinate(Number(area.latitude), Number(area.longitude),
      Number(area.altitude || 0)), Number(area.radius || 0))
  }

  function relevance() {
    var value = String(renderer.prop("relevance", "unspecified"))
    if (value === "distance") return PlaceSearchModel.DistanceHint
    if (value === "lexical") return PlaceSearchModel.LexicalPlaceNameHint
    return PlaceSearchModel.UnspecifiedHint
  }

  function visibilityScope() {
    var value = String(renderer.prop("visibility", "unspecified"))
    if (value === "device") return Place.DeviceVisibility
    if (value === "private") return Place.PrivateVisibility
    if (value === "public") return Place.PublicVisibility
    return Place.UnspecifiedVisibility
  }

  function statusName(value) { return ["null", "ready", "loading", "error"][Number(value)] || "unknown" }

  function serializePlace(place) {
    if (!place) return null
    var location = place.location
    var coordinate = location ? location.coordinate : null
    var address = location ? location.address : null
    return {
      place_id: String(place.placeId), name: String(place.name), attribution: String(place.attribution),
      latitude: coordinate ? coordinate.latitude : null, longitude: coordinate ? coordinate.longitude : null,
      altitude: coordinate ? coordinate.altitude : null,
      address: address ? { text: String(address.text), country: String(address.country),
        country_code: String(address.countryCode), state: String(address.state), county: String(address.county),
        city: String(address.city), district: String(address.district), street: String(address.street),
        postal_code: String(address.postalCode) } : null,
      phone: String(place.primaryPhone), fax: String(place.primaryFax), email: String(place.primaryEmail),
      website: String(place.primaryWebsite), details_fetched: place.detailsFetched
    }
  }

  function publish() {
    var values = []
    for (var index = 0; index < nativeModel.count; index++) {
      values.push({ type: Number(nativeModel.data(index, "type")), title: String(nativeModel.data(index, "title")),
        distance: Number(nativeModel.data(index, "distance")), sponsored: nativeModel.data(index, "sponsored") === true,
        place: serializePlace(nativeModel.data(index, "place")) })
    }
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "results", {
      values: values, count: values.length, previous_page: nativeModel.previousPagesAvailable,
      next_page: nativeModel.nextPagesAvailable
    })
  }

  function processCommand() {
    var revision = Number(renderer.prop("command_revision", 0))
    if (revision === handledCommandRevision) return
    var first = handledCommandRevision < 0
    handledCommandRevision = revision
    if (first && revision <= 0) return
    var command = String(renderer.prop("command", "update"))
    if (command === "cancel") nativeModel.cancel()
    else if (command === "reset") nativeModel.reset()
    else if (command === "next_page") nativeModel.nextPage()
    else if (command === "previous_page") nativeModel.previousPage()
    else nativeModel.update()
  }

  Component { id: parameterComponent; PluginParameter {} }
  Plugin { id: nativePlugin }
  PlaceSearchModel {
    id: nativeModel
    plugin: nativePlugin
    searchTerm: String(root.renderer.prop("term", ""))
    searchArea: root.searchArea()
    limit: Number(root.renderer.prop("limit", -1))
    recommendationId: String(root.renderer.prop("recommendation_id", ""))
    relevanceHint: root.relevance()
    visibilityScope: root.visibilityScope()
    incremental: root.renderer.prop("incremental", false) === true
    onStatusChanged: {
      var name = root.statusName(status)
      root.renderer.bridge.sendEvent(root.renderer.surfaceName, root.renderer.controlId, "status", { value: name })
      if (name === "ready") root.publish()
      else if (name === "error") root.renderer.componentError("place_search_failed", errorString(), {})
    }
    onDataChanged: root.publish()
  }
  Component.onCompleted: { configurePlugin(); processCommand() }
  Connections { target: renderer; function onNodeChanged() { root.configurePlugin(); root.processCommand() } }
}
