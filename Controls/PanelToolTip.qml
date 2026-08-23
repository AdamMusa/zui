import QtQuick
import QtQuick.Controls as QQC
import "../Theme"

QQC.ToolTip {
  property color panelForeground: Color.tooltip.text
  property color panelBackground: Color.tooltip.background
  property color panelBorder: Color.tooltip.border
  property string fontFamily: Style.font.family
  property real fontSize: Style.font.bodySmall
  contentItem: Text { text: parent.text; color: parent.panelForeground; font.family: parent.fontFamily; font.pixelSize: parent.fontSize }
  background: Rectangle { color: parent.panelBackground; radius: Style.cornerRadius; border.color: parent.panelBorder }
}
