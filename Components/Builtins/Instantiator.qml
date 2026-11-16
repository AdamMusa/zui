import QtQuick
import QtQml.Models

Item {
  id: instantiatorRoot

  required property var renderer
  property alias instantiator: nativeInstantiator
  readonly property var childNodes: renderer.node && Array.isArray(renderer.node.children)
    ? renderer.node.children : []

  implicitWidth: childrenRect.width
  implicitHeight: childrenRect.height
  visible: renderer.prop("visible", true) !== false

  function attach(instance) {
    if (!instance) return
    instance.parent = instantiatorRoot
  }

  function publishCount() {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "count_change", { value: nativeInstantiator.count })
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "change", { count: nativeInstantiator.count, active: nativeInstantiator.active })
  }

  Instantiator {
    id: nativeInstantiator
    model: instantiatorRoot.childNodes
    active: renderer.prop("active", true) !== false
    asynchronous: renderer.prop("asynchronous", false) === true
    delegate: renderer.childDelegateComponent

    onObjectAdded: function(index, object) {
      instantiatorRoot.attach(object)
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
        "object_added", { index: index })
      instantiatorRoot.publishCount()
    }
    onObjectRemoved: function(index, object) {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
        "object_removed", { index: index })
      instantiatorRoot.publishCount()
    }
  }
}
