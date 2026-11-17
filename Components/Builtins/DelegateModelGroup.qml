import QtQuick
import QtQml.Models
import "Support" as Support

Item {
  id: groupRoot

  property var renderer: null
  property alias model: nativeDelegateModel
  property alias group: nativeGroup
  readonly property bool dynamicRoleModel:
    renderer === null || renderer.prop("dynamic_roles", true) !== false

  function rebuild() {
    if (!renderer) return
    var rows = rowHelper.normalize(renderer.prop("items", []))

    if (!dynamicRoleModel) {
      var changed = rowHelper.conflicts(rows)
      if (changed.length > 0) {
        renderer.componentError("delegate_model_group_role_type_conflict",
          "Role " + changed[0].role + " changed from " + changed[0].was + " to "
            + changed[0].now + ", which a delegate_model_group with dynamic_roles "
            + "disabled cannot represent",
          { roles: changed })
        return
      }
    }

    rowHelper.fill(sourceModel, rows)
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "count_change", { value: nativeGroup.count })
  }

  Support.ModelRows { id: rowHelper }

  ListModel {
    id: sourceModel
    dynamicRoles: groupRoot.dynamicRoleModel
  }

  DelegateModel {
    id: nativeDelegateModel
    model: sourceModel
    delegate: Item { required property int index }
    groups: [
      DelegateModelGroup {
        id: nativeGroup
        name: String(renderer ? renderer.prop("name", "group") : "group")
        includeByDefault: renderer !== null
          && renderer.prop("include_by_default", false) === true
        onCountChanged: {
          if (renderer) {
            renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
              "change", { value: count })
          }
        }
      }
    ]
  }

  Component.onCompleted: rebuild()
  Connections { target: renderer; function onNodeChanged() { groupRoot.rebuild() } }
}
