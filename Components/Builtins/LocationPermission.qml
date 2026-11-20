import QtQuick
import QtCore as Core
import "Support" as Support

Item {
  id: root
  required property var renderer
  visible: false
  Core.LocationPermission {
    id: nativePermission
    availability: String(root.renderer.prop("availability", "when_in_use")) === "always" ? Core.LocationPermission.Always : Core.LocationPermission.WhenInUse
    accuracy: String(root.renderer.prop("accuracy", "precise")) === "approximate" ? Core.LocationPermission.Approximate : Core.LocationPermission.Precise
  }
  Support.PermissionBridge { renderer: root.renderer; permission: nativePermission }
}
