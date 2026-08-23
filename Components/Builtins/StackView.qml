import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.StackView {
  id: stackRoot

  required property var renderer
  readonly property int childCount: renderer.node && Array.isArray(renderer.node.children)
    ? renderer.node.children.length : 0
  readonly property string childSignature: {
    var ids = []
    for (var index = 0; index < childCount; index++) ids.push(String(renderer.node.children[index].id))
    return ids.join("\u001f")
  }
  readonly property int requestedIndex: Number(renderer.prop("current_index", 0))
  property var pageObjects: []
  property bool initialized: false
  property bool rebuilding: false

  function boundedIndex(value) {
    return childCount === 0 ? -1 : Math.max(0, Math.min(childCount - 1, Number(value)))
  }

  function operationFor(target) {
    return renderer.prop("animated", true) !== false && initialized
      && Math.abs(target - (depth - 1)) === 1
      ? QQC.StackView.PushTransition : QQC.StackView.Immediate
  }

  function pageAt(index) {
    if (pageObjects[index]) return pageObjects[index]
    var page = renderer.childDelegateComponent.createObject(stackRoot, {
      modelData: renderer.node.children[index]
    })
    if (!page) return null
    var pages = pageObjects.slice(0)
    pages[index] = page
    pageObjects = pages
    return page
  }

  function syncNavigation() {
    if (!initialized || rebuilding || busy) return
    var target = boundedIndex(requestedIndex)
    if (target < 0) {
      if (depth > 0) clear(QQC.StackView.Immediate)
      return
    }

    var current = depth - 1
    if (current < target) {
      var nextIndex = current + 1
      var page = pageAt(nextIndex)
      if (!page) return
      push(page, {}, operationFor(target))
      if (renderer.subscribed("push"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "push",
          { value: nextIndex, depth: depth })
      if (!busy) Qt.callLater(syncNavigation)
    } else if (current > target) {
      pop(operationFor(target) === QQC.StackView.PushTransition
        ? QQC.StackView.PopTransition : QQC.StackView.Immediate)
      if (renderer.subscribed("pop"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "pop",
          { value: Math.max(-1, depth - 1), depth: depth })
      if (!busy) Qt.callLater(syncNavigation)
    }
  }

  function rebuildPages() {
    if (!initialized) return
    rebuilding = true
    clear(QQC.StackView.Immediate)
    var oldPages = pageObjects
    pageObjects = []
    for (var index = 0; index < oldPages.length; index++) {
      if (oldPages[index]) oldPages[index].destroy()
    }
    rebuilding = false
    Qt.callLater(syncNavigation)
  }

  implicitWidth: Number(renderer.prop("width", 640))
  implicitHeight: Number(renderer.prop("height", 420))
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false
  clip: renderer.prop("clip", true) !== false

  background: Rectangle {
    color: renderer.prop("background", Color.background)
    radius: Number(renderer.prop("radius", 0))
    border.width: String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0
    border.color: renderer.prop("border_color", "transparent")
  }

  Component.onCompleted: {
    initialized = true
    syncNavigation()
  }
  onRequestedIndexChanged: syncNavigation()
  onChildSignatureChanged: rebuildPages()
  onBusyChanged: {
    if (renderer.subscribed("busy_change"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "busy_change", { value: busy })
    if (!busy) Qt.callLater(syncNavigation)
  }
  onDepthChanged: {
    if (!initialized || rebuilding) return
    var index = depth - 1
    if (renderer.subscribed("depth_change"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "depth_change",
        { value: depth, index: index })
    if (renderer.subscribed("change"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change",
        { value: index, depth: depth })
  }
  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
  onActiveFocusChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    activeFocus ? "focus" : "blur", {})
}
