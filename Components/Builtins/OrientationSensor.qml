import QtQuick
import QtSensors as Sensors
import "Support" as Support
Item { id: root; required property var renderer; visible: false; Sensors.OrientationSensor { id: nativeSensor } Support.SensorBridge { renderer: root.renderer; sensor: nativeSensor; fields: ["orientation"] } }
