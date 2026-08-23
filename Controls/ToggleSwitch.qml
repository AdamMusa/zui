import QtQuick
import "../Theme"

Item {
  id: root
  property bool checked: false
  property bool busy: false
  property bool interactive: true
  property bool hasCursor: false
  property bool cursorRing: true
  property real cursorPad: 6
  property bool rounded: true
  property color foreground: Color.foreground
  property color accent: Color.accent
  property real trackHeight: 24
  property real trackWidth: 46
  property real knobSize: 18
  property real knobInset: 3
  signal toggled()
  signal hovered(bool value)
  implicitWidth: trackWidth
  implicitHeight: trackHeight
  Rectangle { anchors.fill: parent; radius: root.rounded ? height / 2 : 2; color: root.checked ? root.accent : Color.muted; opacity: root.busy ? 0.55 : 1 }
  Rectangle { width: root.knobSize; height: root.knobSize; radius: root.rounded ? width / 2 : 2; color: root.foreground; y: root.knobInset; x: root.checked ? root.trackWidth - width - root.knobInset : root.knobInset; Behavior on x { NumberAnimation { duration: 140 } } }
  MouseArea { anchors.fill: parent; enabled: root.interactive && !root.busy; hoverEnabled: true; cursorShape: root.hasCursor ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: root.toggled(); onContainsMouseChanged: root.hovered(containsMouse) }
}
