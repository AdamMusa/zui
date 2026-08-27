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

  function statusName(value) { return ["null", "ready", "loading", "error"][Number(value)] || "unknown" }

  function processCommand() {
    var revision = Number(renderer.prop("command_revision", 0))
    if (revision === handledCommandRevision) return
    var first = handledCommandRevision < 0
    handledCommandRevision = revision
    if (first && revision <= 0) return
    var command = String(renderer.prop("command", "update"))
    if (command === "cancel") nativeModel.cancel()
    else if (command === "reset") nativeModel.reset()
    else nativeModel.update()
  }

  Component { id: parameterComponent; PluginParameter {} }
  Plugin { id: nativePlugin }
  PlaceSearchSuggestionModel {
    id: nativeModel
    plugin: nativePlugin
    searchTerm: String(root.renderer.prop("term", ""))
    searchArea: root.searchArea()
    limit: Number(root.renderer.prop("limit", -1))
    onStatusChanged: {
      var name = root.statusName(status)
      root.renderer.bridge.sendEvent(root.renderer.surfaceName, root.renderer.controlId, "status", { value: name })
      if (name === "ready") root.renderer.bridge.sendEvent(root.renderer.surfaceName, root.renderer.controlId,
        "suggestions", { values: suggestions.map(String), count: suggestions.length })
      else if (name === "error") root.renderer.componentError("place_suggestions_failed", errorString(), {})
    }
  }
  Component.onCompleted: { configurePlugin(); processCommand() }
  Connections { target: renderer; function onNodeChanged() { root.configurePlugin(); root.processCommand() } }
}
