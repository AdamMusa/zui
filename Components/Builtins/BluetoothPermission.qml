import QtQuick
import QtCore
import "Support" as Support

Item {
  id: root
  required property var renderer
  visible: false
  function modes() {
    var values = Array.isArray(renderer.prop("communication_modes", [])) ? renderer.prop("communication_modes", []) : [renderer.prop("communication_modes", "default")]
    var result = BluetoothPermission.Default
    for (var index = 0; index < values.length; index++) {
      if (String(values[index]) === "access") result |= BluetoothPermission.Access
      else if (String(values[index]) === "advertise") result |= BluetoothPermission.Advertise
    }
    return result
  }
  BluetoothPermission { id: nativePermission; communicationModes: root.modes() }
  Support.PermissionBridge { renderer: root.renderer; permission: nativePermission }
}
