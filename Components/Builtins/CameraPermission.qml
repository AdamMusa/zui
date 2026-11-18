import QtQuick
import QtCore as Core
import "Support" as Support

Item {
  id: root
  required property var renderer
  visible: false
  Core.CameraPermission { id: nativePermission }
  Support.PermissionBridge { renderer: root.renderer; permission: nativePermission }
}
