import QtQuick
import "../Theme"

Item {
  id: root
  property string label: ""
  property string description: ""
  property bool checked: false
  property bool hasCursor: false
  property bool rounded: true
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property real titleSize: Style.font.subtitle
  property real descriptionSize: Style.font.caption
  signal clicked()
  signal hovered(bool value)
  implicitWidth: content.implicitWidth
  implicitHeight: Math.max(toggle.implicitHeight, labels.implicitHeight)
  Row { id: content; spacing: Style.spacing.controlGap; ToggleSwitch { id: toggle; checked: root.checked; accent: root.accent; foreground: root.foreground; interactive: false } Column { id: labels; Text { text: root.label; color: root.foreground; font.family: root.fontFamily; font.pixelSize: root.titleSize } Text { text: root.description; visible: text !== ""; color: root.foreground; opacity: 0.65; font.family: root.fontFamily; font.pixelSize: root.descriptionSize } } }
  MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: root.hasCursor ? Qt.PointingHandCursor : Qt.ArrowCursor; onClicked: root.clicked(); onContainsMouseChanged: root.hovered(containsMouse) }
}
