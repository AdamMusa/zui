import QtQuick
import QtSensors
import "Support" as Support
Item { id: root; required property var renderer; visible: false; Accelerometer { id: nativeSensor } Support.SensorBridge { renderer: root.renderer; sensor: nativeSensor; fields: ["x", "y", "z"] } }
