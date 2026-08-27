import QtQuick
import QtSensors
import "Support" as Support
Item {
  id: root
  required property var renderer
  visible: false
  TapSensor { id: nativeSensor; returnDoubleTapEvents: root.renderer.prop("return_double_tap_events", true) !== false }
  Support.SensorBridge { renderer: root.renderer; sensor: nativeSensor; fields: ["tapDirection", "doubleTap"] }
}
