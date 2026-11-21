import QtQuick
import QtQml

Item {
  id: propertyBindingRoot

  required property var renderer

  readonly property var targetItem: renderer.findRenderedItem(renderer.prop("target", ""))
  readonly property var sourceItem: String(renderer.prop("source", "")) === ""
    ? null : renderer.findRenderedItem(renderer.prop("source", ""))
  readonly property string propertyName: propertyBindingRoot.resolvedName(targetItem, renderer.prop("property", ""))
  readonly property string sourcePropertyName:
    propertyBindingRoot.resolvedName(sourceItem, renderer.prop("source_property", ""))

  // With no source property the binding carries the value Ruby declared. With
  // one it follows that property live, so the link is re-evaluated by QML
  // instead of round-tripping through Ruby on every change.
  readonly property bool tracking: sourceItem !== null && sourcePropertyName !== ""
  readonly property var boundValue: tracking
    ? sourceItem[sourcePropertyName] : renderer.prop("value", undefined)
  readonly property bool enabled: renderer.prop("when", true) !== false
  // Qt warns and does nothing when a Binding names a property the target does
  // not have, so never hand it one: validate() reports that case to Ruby.
  readonly property bool resolvable: targetItem !== null && propertyName !== ""
    && targetItem.hasOwnProperty(propertyName)
    && (String(renderer.prop("source", "")) === ""
      || (sourceItem !== null && sourceItem.hasOwnProperty(sourcePropertyName)))

  implicitWidth: 0
  implicitHeight: 0
  visible: false

  function resolvedName(item, requested) {
    var name = String(requested || "")
    if (name === "") return ""
    if (item && item.hasOwnProperty(name)) return name
    var camel = name.replace(/_([a-z])/g, function(match, letter) { return letter.toUpperCase() })
    if (item && item.hasOwnProperty(camel)) return camel
    return name
  }

  function restoreModeValue() {
    var name = String(renderer.prop("restore_mode", "binding_or_value"))
    if (name === "none") return Binding.RestoreNone
    if (name === "binding") return Binding.RestoreBinding
    if (name === "value") return Binding.RestoreValue
    return Binding.RestoreBindingOrValue
  }

  function publish() {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", {
      value: boundValue === undefined ? null : boundValue,
      property: propertyName, tracking: tracking, active: enabled
    })
  }

  // A binding that cannot reach its target or property would otherwise do
  // nothing at all, so report it instead of leaving a dead link behind.
  function validate() {
    var requestedTarget = String(renderer.prop("target", ""))
    if (requestedTarget === "") {
      renderer.componentError("binding_without_target", "A binding needs a target control id", {})
      return
    }
    if (!targetItem) {
      renderer.componentError("binding_target_missing",
        "No rendered control matches the binding target",
        { target: requestedTarget })
      return
    }
    var requestedProperty = String(renderer.prop("property", ""))
    if (requestedProperty === "") {
      renderer.componentError("binding_without_property",
        "A binding needs the name of a target property", { target: requestedTarget })
      return
    }
    if (!targetItem.hasOwnProperty(propertyName)) {
      renderer.componentError("binding_property_missing",
        "The binding target has no property " + requestedProperty,
        { target: requestedTarget, property: requestedProperty })
      return
    }
    var requestedSource = String(renderer.prop("source", ""))
    if (requestedSource !== "" && !sourceItem) {
      renderer.componentError("binding_source_missing",
        "No rendered control matches the binding source",
        { source: requestedSource })
      return
    }
    if (requestedSource !== "" && !sourceItem.hasOwnProperty(sourcePropertyName)) {
      renderer.componentError("binding_source_property_missing",
        "The binding source has no property " + String(renderer.prop("source_property", "")),
        { source: requestedSource, property: String(renderer.prop("source_property", "")) })
      return
    }
    publish()
  }

  Binding {
    id: nativeBinding
    target: propertyBindingRoot.targetItem
    property: propertyBindingRoot.propertyName
    value: propertyBindingRoot.boundValue
    when: propertyBindingRoot.enabled && propertyBindingRoot.resolvable
    delayed: renderer.prop("delayed", false) === true
    restoreMode: propertyBindingRoot.restoreModeValue()
  }

  onBoundValueChanged: if (enabled && resolvable) publish()
  Component.onCompleted: Qt.callLater(validate)
  Connections { target: renderer; function onNodeChanged() { Qt.callLater(propertyBindingRoot.validate) } }
}
