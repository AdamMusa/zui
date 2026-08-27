import QtQuick
import QtCore
import "Support" as Support

Item {
  id: root
  required property var renderer
  visible: false
  CameraPermission { id: nativePermission }
  Support.PermissionBridge { renderer: root.renderer; permission: nativePermission }
}
