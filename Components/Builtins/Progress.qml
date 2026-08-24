import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Rectangle {
  required property var renderer
      property real minimum: Number(renderer.prop("minimum", 0)); property real maximum: Number(renderer.prop("maximum", 1))
      implicitWidth: Number(renderer.prop("width", 200)); implicitHeight: Number(renderer.prop("height", 6)); radius: height / 2
      color: Qt.rgba(renderer.foreground.r, renderer.foreground.g, renderer.foreground.b, 0.18)
      Rectangle { width: parent.width * Math.max(0, Math.min(1, (Number(renderer.prop("value", 0)) - parent.minimum) / Math.max(0.000001, parent.maximum - parent.minimum))); height: parent.height; radius: parent.radius; color: renderer.prop("color", renderer.foreground) }
    }
