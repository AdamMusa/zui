import QtQuick
import QtQml.Models
import QtLocation

Item {
  id: root
  required property var renderer
  property var parameterObjects: []
  property int handledCommandRevision: -1
  property bool queryRequested: false
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

  function publish() {
    var values = []
    for (var index = 0; index < rows.count; index++) values.push(rows.objectAt(index).payload)
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "categories", { values: values, count: values.length })
  }

  function statusName(value) { return ["null", "ready", "loading", "error"][Number(value)] || "unknown" }

  function processCommand() {
    var revision = Number(renderer.prop("command_revision", 0))
    if (revision === handledCommandRevision) return
    var first = handledCommandRevision < 0
    handledCommandRevision = revision
    if (first && revision <= 0) return
    queryRequested = true
    Qt.callLater(nativeModel.update)
  }

  Component { id: parameterComponent; PluginParameter {} }
  Plugin { id: nativePlugin }
  CategoryModel {
    id: nativeModel
    plugin: root.queryRequested ? nativePlugin : null
    hierarchical: root.renderer.prop("hierarchical", false) === true
    onStatusChanged: {
      var name = root.statusName(status)
      root.renderer.bridge.sendEvent(root.renderer.surfaceName, root.renderer.controlId, "status", { value: name })
      if (name === "ready") Qt.callLater(root.publish)
      else if (name === "error") root.renderer.componentError("place_categories_failed", errorString(), {})
    }
  }
  Instantiator {
    id: rows
    model: nativeModel
    delegate: QtObject {
      required property var model
      readonly property var value: model.category
      readonly property var parentValue: model.parent
      readonly property var payload: ({ category_id: String(value.categoryId), name: String(value.name),
        parent_id: parentValue ? String(parentValue.categoryId) : "" })
    }
    onObjectAdded: Qt.callLater(root.publish)
    onObjectRemoved: Qt.callLater(root.publish)
  }
  Component.onCompleted: { configurePlugin(); processCommand() }
  Connections { target: renderer; function onNodeChanged() { root.configurePlugin(); root.processCommand() } }
}
