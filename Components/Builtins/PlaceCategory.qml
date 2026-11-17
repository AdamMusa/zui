import QtQuick
import QtLocation

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
    if (value === "device") return Category.DeviceVisibility
    if (value === "private") return Category.PrivateVisibility
    if (value === "public") return Category.PublicVisibility
    return Category.UnspecifiedVisibility
  }

  function statusName(value) { return ["ready", "saving", "removing", "error"][Number(value)] || "unknown" }

  function publish(eventName) {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, eventName,
      { category_id: String(nativeCategory.categoryId), name: String(nativeCategory.name) })
  }

  function processCommand() {
    var revision = Number(renderer.prop("command_revision", 0))
    if (revision === handledCommandRevision) return
    var first = handledCommandRevision < 0
    handledCommandRevision = revision
    if (first && revision <= 0) return
    var command = String(renderer.prop("command", "details"))
    pendingOperation = command
    if (command === "save") nativeCategory.save()
    else if (command === "remove") nativeCategory.remove()
    else publish("details")
  }

  Component { id: parameterComponent; PluginParameter {} }
  Plugin { id: nativePlugin }
  Category {
    id: nativeCategory
    plugin: nativePlugin
    categoryId: String(root.renderer.prop("category_id", ""))
    name: String(root.renderer.prop("name", ""))
    visibility: root.visibilityValue()
    onStatusChanged: {
      var name = root.statusName(status)
      root.renderer.bridge.sendEvent(root.renderer.surfaceName, root.renderer.controlId, "status", { value: name })
      if (name === "ready") root.publish(root.pendingOperation === "remove" ? "removed" : "saved")
      else if (name === "error") root.renderer.componentError("place_category_operation_failed", errorString(), {})
    }
  }
  Component.onCompleted: { configurePlugin(); publish("details"); processCommand() }
  Connections { target: renderer; function onNodeChanged() { root.configurePlugin(); root.processCommand() } }
}
