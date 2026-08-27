import QtQuick
import QtCore
import "Support" as Support

Item {
  id: root
  required property var renderer
  property string appliedAccessMode: "read_write"
  visible: false

  function synchronizeAccessMode() {
    var requested = String(renderer.prop("access_mode", "read_write"))
    var desired = requested === "read_only" ? "read_only" : "read_write"
    if (desired === appliedAccessMode) return
    appliedAccessMode = desired
    nativePermission.accessMode = desired === "read_only"
      ? ContactsPermission.ReadOnly : ContactsPermission.ReadWrite
  }

  ContactsPermission {
    id: nativePermission
    accessMode: ContactsPermission.ReadWrite
  }
  Support.PermissionBridge { renderer: root.renderer; permission: nativePermission }
  Component.onCompleted: synchronizeAccessMode()
  Connections { target: renderer; function onNodeChanged() { root.synchronizeAccessMode() } }
}
