import QtQuick
import "../Theme"

Item {
  id: root
  property bool active: false
  property string activeText: ""
  property string inactiveText: ""
  property string activeTooltipText: ""
  property string inactiveTooltipText: ""
  property string indicatorBlock: "single"
  property color foreground: Color.foreground
  property color activeColor: Color.accent
  property string fontFamily: Fonts.iconFamily
  property real fontSize: Style.font.caption
  signal pressed(int button)
  signal wheelMoved(real delta)
  implicitWidth: label.implicitWidth
  implicitHeight: Math.max(Style.spacing.controlHeight, label.implicitHeight)
  Text { id: label; anchors.centerIn: parent; text: root.active ? root.activeText : root.inactiveText; color: root.active ? root.activeColor : root.foreground; font.family: root.fontFamily; font.pixelSize: root.fontSize }
  MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: function(event) { root.pressed(event.button) }; onWheel: function(event) { root.wheelMoved(event.angleDelta.y) } }
}
