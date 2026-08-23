import QtQuick
import "../Theme"

Rectangle {
  property bool current: false
  property bool hasCursor: false
  property color foreground: Color.foreground
  property color accent: Color.accent
  property color currentFill: Qt.rgba(accent.r, accent.g, accent.b, 0.18)
  color: current ? currentFill : "transparent"
  radius: Style.cornerRadius
}
