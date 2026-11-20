import QtQuick
import "Support" as Support

Item {
  id: modelRoot

  property var renderer: null
  property alias model: nativeModel
  readonly property bool dynamicRoleModel:
    renderer === null || renderer.prop("dynamic_roles", true) !== false

  function rebuild() {
    if (!renderer) return
    var rows = rowHelper.normalize(renderer.prop("items", []))

    if (!dynamicRoleModel) {
      var changed = rowHelper.conflicts(rows)
      if (changed.length > 0) {
        renderer.componentError("list_model_role_type_conflict",
          "Role " + changed[0].role + " changed from " + changed[0].was + " to "
            + changed[0].now + ", which a list_model with dynamic_roles disabled "
            + "cannot represent",
          { roles: changed })
        return
      }
    }

    rowHelper.fill(nativeModel, rows)
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "count_change", { value: nativeModel.count })
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      "change", { count: nativeModel.count })
  }

  Support.ModelRows { id: rowHelper }

  ListModel {
    id: nativeModel
    // Ruby owns the row shape and the model is rebuilt wholesale on every
    // change, so the fixed-role fast path was never being exploited anyway.
    // Qt only honours dynamicRoles while the model is empty, hence a binding.
    dynamicRoles: modelRoot.dynamicRoleModel
  }

  Component.onCompleted: rebuild()
  Connections { target: renderer; function onNodeChanged() { modelRoot.rebuild() } }
}
