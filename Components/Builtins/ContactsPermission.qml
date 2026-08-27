import QtQuick
import QtCore
import "Support" as Support

Item {
  id: root
  required property var renderer
  visible: false
  ContactsPermission {
    id: nativePermission
    accessMode: String(root.renderer.prop("access_mode", "read_write")) === "read_only" ? ContactsPermission.ReadOnly : ContactsPermission.ReadWrite
  }
  Support.PermissionBridge { renderer: root.renderer; permission: nativePermission }
}
