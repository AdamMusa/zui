import QtQuick
import QtCore
import "Support" as Support

Item {
  id: root
  required property var renderer
  visible: false
  LocationPermission {
    id: nativePermission
    availability: String(root.renderer.prop("availability", "when_in_use")) === "always" ? LocationPermission.Always : LocationPermission.WhenInUse
    accuracy: String(root.renderer.prop("accuracy", "precise")) === "approximate" ? LocationPermission.Approximate : LocationPermission.Precise
  }
  Support.PermissionBridge { renderer: root.renderer; permission: nativePermission }
}
