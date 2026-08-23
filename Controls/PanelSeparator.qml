import QtQuick
import "../Theme"

Rectangle {
  property color foreground: Color.foreground
  property real strength: 0.12
  implicitWidth: 160
  implicitHeight: 1
  color: Qt.rgba(foreground.r, foreground.g, foreground.b, strength)
}
