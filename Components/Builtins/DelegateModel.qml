import QtQuick
import QtQml.Models
import "Support" as Support

Item {
  id: modelRoot

  property var renderer: null
  property alias model: nativeDelegateModel
  readonly property bool dynamicRoleModel:
    renderer === null || renderer.prop("dynamic_roles", true) !== false

  function rebuild() {
    if (!renderer) return
    var rows = rowHelper.normalize(renderer.prop("items", []))

    if (!dynamicRoleModel) {
      var changed = rowHelper.conflicts(rows)
      if (changed.length > 0) {
        renderer.componentError("delegate_model_role_type_conflict",
          "Role " + changed[0].role + " changed from " + changed[0].was + " to "
            + changed[0].now + ", which a delegate_model with dynamic_roles "
            + "disabled cannot represent",
          { roles: changed })
        return
      }
    }

    rowHelper.fill(sourceModel, rows)
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "count_change", { value: nativeDelegateModel.count })
  }

  Support.ModelRows { id: rowHelper }

  ListModel {
    id: sourceModel
    dynamicRoles: modelRoot.dynamicRoleModel
  }

  DelegateModel {
    id: nativeDelegateModel
    model: sourceModel
    filterOnGroup: String(renderer ? renderer.prop("filter_group", "items") : "items")
    delegate: Item {
      required property int index
      property var sourceIndex: index
    }
  }

  Component.onCompleted: rebuild()
  Connections { target: renderer; function onNodeChanged() { modelRoot.rebuild() } }
}
