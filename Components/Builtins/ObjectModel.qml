import QtQuick
import QtQml.Models

Item {
  id: objectModelRoot

  required property var renderer
  property alias model: nativeModel
  property int handledRevision: -1
  readonly property var childNodes: renderer.node && Array.isArray(renderer.node.children)
    ? renderer.node.children : []

  implicitWidth: 0
  implicitHeight: 0
  visible: renderer.prop("visible", true) !== false

  function publish() {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "count_change", { value: nativeModel.count })
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "change", { count: nativeModel.count })
  }

  function resync() {
    nativeModel.clear()
    for (var index = 0; index < childRepeater.count; index++) {
      var instance = childRepeater.itemAt(index)
      if (instance) nativeModel.append(instance)
    }
    publish()
  }

  function republish() {
    var revision = Number(renderer.prop("revision", 0))
    if (revision === handledRevision) return
    handledRevision = revision
    publish()
  }

  ObjectModel { id: nativeModel }

  Item {
    id: childHost
    width: 0
    height: 0
    visible: false

    Repeater {
      id: childRepeater
      model: objectModelRoot.childNodes
      delegate: renderer.childDelegateComponent
      onItemAdded: Qt.callLater(objectModelRoot.resync)
      onItemRemoved: Qt.callLater(objectModelRoot.resync)
    }
  }

  // The first publish waits for the repeater, so Ruby is never told the model
  // is empty before its declared children have been created.
  Component.onCompleted: {
    handledRevision = Number(renderer.prop("revision", 0))
    Qt.callLater(resync)
  }
  Connections { target: renderer; function onNodeChanged() { objectModelRoot.republish() } }
}
