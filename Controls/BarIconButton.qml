import QtQuick
import "../Theme"

Item {
  id: root
  property string text: ""
  property string tooltipText: ""
  property bool active: false
  property color foreground: Color.foreground
  property color activeColor: Color.accent
  property real slotSize: 30
  property real opticalSize: 18
  property string fontFamily: Fonts.iconFamily
  property real fontSize: Style.font.icon
  property real textRotation: 0
  property bool keepSpace: false
  property bool dimmed: false
  property bool concealed: false
  property bool interactive: true
  signal pressed(int button)
  signal wheelMoved(real delta)
  implicitWidth: concealed && !keepSpace ? 0 : slotSize
  implicitHeight: slotSize
  opacity: concealed ? 0 : (dimmed ? 0.45 : 1)
  Text { anchors.centerIn: parent; text: root.text; color: root.active ? root.activeColor : root.foreground; font.family: root.fontFamily; font.pixelSize: root.fontSize; rotation: root.textRotation }
  MouseArea { anchors.fill: parent; enabled: root.interactive; acceptedButtons: Qt.AllButtons; onClicked: function(event) { root.pressed(event.button) }; onWheel: function(event) { root.wheelMoved(event.angleDelta.y) } }
}
