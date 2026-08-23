import QtQuick
import "../Theme"

Item {
  id: root
  property string text: ""
  property string tooltipText: ""
  property bool active: false
  property bool dimmed: false
  property bool concealed: false
  property bool interactive: true
  property bool pressable: true
  property string fontFamily: Style.font.family
  property real fontSize: Style.font.body
  property color foreground: Color.foreground
  property color activeColor: Color.accent
  property real horizontalMargin: 8.5
  property real verticalPadding: 6
  property real fixedWidth: -1
  property real fixedHeight: -1
  property real textRotation: 0
  property bool keepSpace: false
  property bool useActiveColor: true
  property bool maintainIndicatorReveal: false
  property bool labelVisible: true
  property bool hasVisualContent: text !== ""
  signal pressed(int button)
  signal wheelMoved(real delta)
  implicitWidth: fixedWidth >= 0 ? fixedWidth : label.implicitWidth + horizontalMargin * 2
  implicitHeight: fixedHeight >= 0 ? fixedHeight : label.implicitHeight + verticalPadding * 2
  opacity: concealed ? 0 : (dimmed ? 0.45 : 1)
  visible: !concealed || keepSpace
  Text { id: label; anchors.centerIn: parent; visible: root.labelVisible; text: root.text; color: root.active && root.useActiveColor ? root.activeColor : root.foreground; font.family: root.fontFamily; font.pixelSize: root.fontSize; rotation: root.textRotation }
  MouseArea { anchors.fill: parent; enabled: root.interactive && root.pressable; acceptedButtons: Qt.AllButtons; onClicked: function(event) { root.pressed(event.button) }; onWheel: function(event) { root.wheelMoved(event.angleDelta.y) } }
}
