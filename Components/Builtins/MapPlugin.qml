import QtQuick
import QtLocation

Item {
  id: root
  required property var renderer
  readonly property alias plugin: nativePlugin
  property var parameterObjects: []
  property int handledRefreshRevision: -1
  visible: false

  readonly property var mappingFlags: ({
    no: Plugin.NoMappingFeatures, online: Plugin.OnlineMappingFeature,
    offline: Plugin.OfflineMappingFeature, localized: Plugin.LocalizedMappingFeature,
    any: Plugin.AnyMappingFeatures
  })
  readonly property var routingFlags: ({
    no: Plugin.NoRoutingFeatures, online: Plugin.OnlineRoutingFeature,
    offline: Plugin.OfflineRoutingFeature, localized: Plugin.LocalizedRoutingFeature,
    route_updates: Plugin.RouteUpdatesFeature, alternative_routes: Plugin.AlternativeRoutesFeature,
    exclude_areas: Plugin.ExcludeAreasRoutingFeature, any: Plugin.AnyRoutingFeatures
  })
  readonly property var geocodingFlags: ({
    no: Plugin.NoGeocodingFeatures, online: Plugin.OnlineGeocodingFeature,
    offline: Plugin.OfflineGeocodingFeature, reverse: Plugin.ReverseGeocodingFeature,
    localized: Plugin.LocalizedGeocodingFeature, any: Plugin.AnyGeocodingFeatures
  })
  readonly property var placesFlags: ({
    no: Plugin.NoPlacesFeatures, online: Plugin.OnlinePlacesFeature,
    offline: Plugin.OfflinePlacesFeature, save_place: Plugin.SavePlaceFeature,
    remove_place: Plugin.RemovePlaceFeature, save_category: Plugin.SaveCategoryFeature,
    remove_category: Plugin.RemoveCategoryFeature, recommendations: Plugin.PlaceRecommendationsFeature,
    search_suggestions: Plugin.SearchSuggestionsFeature, localized: Plugin.LocalizedPlacesFeature,
    notifications: Plugin.NotificationsFeature, place_matching: Plugin.PlaceMatchingFeature,
    any: Plugin.AnyPlacesFeatures
  })
  readonly property var navigationFlags: ({
    no: Plugin.NoNavigationFeatures, online: Plugin.OnlineNavigationFeature,
    offline: Plugin.OfflineNavigationFeature, any: Plugin.AnyNavigationFeatures
  })

  function features(name, table, fallback) {
    var requested = renderer.prop(name, null)
    if (requested === null || requested === undefined || requested === "") return fallback
    if (!Array.isArray(requested)) requested = [requested]
    var flags = 0
    for (var index = 0; index < requested.length; index++) {
      var entry = requested[index]
      if (typeof entry === "number") { flags |= entry; continue }
      var key = String(entry)
      if (table[key] === undefined) {
        renderer.componentError("map_plugin_feature_unknown", "The map plugin requirement is not a Qt provider feature", { requirement: name, feature: key })
        continue
      }
      flags |= table[key]
    }
    return flags
  }

  function stringList(name) {
    var value = renderer.prop(name, [])
    if (!value) return []
    return Array.isArray(value) ? value.map(String) : [String(value)]
  }

  function configureParameters() {
    for (var oldIndex = 0; oldIndex < parameterObjects.length; oldIndex++) parameterObjects[oldIndex].destroy()
    var objects = []
    var values = renderer.prop("plugin_parameters", {}) || {}
    var names = Object.keys(values).sort()
    for (var index = 0; index < names.length; index++)
      objects.push(parameterComponent.createObject(root, { name: names[index], value: values[names[index]] }))
    parameterObjects = objects
    nativePlugin.parameters = objects
  }

  function publish() {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "providers", {
      name: String(nativePlugin.name),
      available: nativePlugin.availableServiceProviders,
      attached: nativePlugin.isAttached === true,
      locales: nativePlugin.locales,
      preferred: nativePlugin.preferred,
      allow_experimental: nativePlugin.allowExperimental === true,
      supports_mapping: nativePlugin.supportsMapping(),
      supports_routing: nativePlugin.supportsRouting(),
      supports_geocoding: nativePlugin.supportsGeocoding(),
      supports_places: nativePlugin.supportsPlaces(),
      supports_navigation: nativePlugin.supportsNavigation()
    })
  }

  function refresh() {
    configureParameters()
    var revision = Number(renderer.prop("refresh_revision", 0))
    if (revision === handledRefreshRevision) return
    handledRefreshRevision = revision
    publish()
  }

  Component { id: parameterComponent; PluginParameter {} }
  Plugin {
    id: nativePlugin
    name: String(root.renderer.prop("name", "osm"))
    locales: root.stringList("locales")
    preferred: root.stringList("preferred")
    allowExperimental: root.renderer.prop("allow_experimental", false) === true
    // PluginRequirements is isCreatable: false, so Qt exposes it as Plugin's grouped
    // "required" property rather than as a type an application can instantiate.
    required.mapping: root.features("required_mapping", root.mappingFlags, Plugin.NoMappingFeatures)
    required.routing: root.features("required_routing", root.routingFlags, Plugin.NoRoutingFeatures)
    required.geocoding: root.features("required_geocoding", root.geocodingFlags, Plugin.NoGeocodingFeatures)
    required.places: root.features("required_places", root.placesFlags, Plugin.NoPlacesFeatures)
    required.navigation: root.features("required_navigation", root.navigationFlags, Plugin.NoNavigationFeatures)
    onAttached: {
      root.renderer.bridge.sendEvent(root.renderer.surfaceName, root.renderer.controlId, "attached", { name: String(nativePlugin.name) })
      root.publish()
    }
    onNameChanged: {
      if (nativePlugin.availableServiceProviders.indexOf(String(nativePlugin.name)) < 0)
        root.renderer.componentError("map_plugin_unavailable", "No Qt geo service provider is installed under that name",
          { plugin: String(nativePlugin.name), available: nativePlugin.availableServiceProviders })
      root.publish()
    }
  }
  Connections { target: renderer; function onNodeChanged() { root.refresh() } }
  Component.onCompleted: refresh()
}
