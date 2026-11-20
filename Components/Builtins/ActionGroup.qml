import QtQuick
import QtQuick.Controls as QQC

Item {
  id: groupRoot

  required property var renderer
  property alias nativeActionGroup: nativeGroup
  property var requestedIds: renderer.prop("action_ids", [])
  property var attached: []

  function attachedIds() {
    var result = []
    for (var index = 0; index < attached.length; index++) result.push(attached[index].id)
    return result
  }

  function actionPayload(action) {
    if (!action) return { value: "", action: "", checked: false }
    for (var index = 0; index < attached.length; index++) {
      if (attached[index].action === action) {
        return { value: attached[index].id, action: attached[index].id, checked: action.checked }
      }
    }
    return { value: "", action: "", checked: action.checked }
  }

  function syncActions() {
    for (var index = 0; index < attached.length; index++) nativeGroup.removeAction(attached[index].action)

    var next = []
    var values = Array.isArray(requestedIds) ? requestedIds : []
    for (index = 0; index < values.length; index++) {
      var actionId = String(values[index])
      var rendered = renderer.findRenderedItem(actionId)
      if (rendered && rendered.nativeAction) {
        nativeGroup.addAction(rendered.nativeAction)
        next.push({ id: actionId, action: rendered.nativeAction })
      }
    }
    attached = next
    syncCheckedAction()
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "actions_change", { values: attachedIds() })
  }

  function syncCheckedAction() {
    var requested = String(renderer.prop("checked_action", "") || "")
    if (!requested.length) return
    for (var index = 0; index < attached.length; index++) {
      if (attached[index].id === requested) {
        nativeGroup.checkedAction = attached[index].action
        return
      }
    }
  }

  implicitWidth: 0
  implicitHeight: 0
  visible: renderer.prop("visible", true) !== false
  onRequestedIdsChanged: syncActionsLater.restart()
  Component.onCompleted: syncActionsLater.restart()
  Component.onDestruction: {
    for (var index = 0; index < attached.length; index++) nativeGroup.removeAction(attached[index].action)
  }

  QQC.ActionGroup {
    id: nativeGroup
    exclusive: renderer.prop("exclusive", true) !== false
    enabled: renderer.prop("enabled", true) !== false && groupRoot.visible

    onTriggered: function(action) {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
        "trigger", groupRoot.actionPayload(action))
    }
    onCheckedActionChanged: {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
        "change", groupRoot.actionPayload(checkedAction))
    }
  }

  // Owned by this node, so a call still pending when the node goes is dropped
  // with it; a bare Qt.callLater runs against a destroyed object instead.
  Timer {
    id: syncActionsLater
    interval: 0
    repeat: false
    onTriggered: syncActions()
  }
}
