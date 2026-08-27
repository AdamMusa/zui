import QtQuick
import QtSensors
import "Support" as Support
Item { id: root; required property var renderer; visible: false; HumiditySensor { id: nativeSensor }; Support.SensorBridge { renderer: root.renderer; sensor: nativeSensor; fields: ["relativeHumidity", "absoluteHumidity"] } }
