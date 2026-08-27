import QtQuick
import QtCore
import "Support" as Support

Item {
  id: root
  required property var renderer
  visible: false
  CalendarPermission {
    id: nativePermission
    accessMode: String(root.renderer.prop("access_mode", "read_write")) === "read_only" ? CalendarPermission.ReadOnly : CalendarPermission.ReadWrite
  }
  Support.PermissionBridge { renderer: root.renderer; permission: nativePermission }
}
