import QtQuick
import QtQuick.Controls as QQC
import "../Theme"

QQC.ToolTip {
  // A Popup does not parent its contentItem or its background to itself: both
  // are reparented onto the popup's own internal item, which has none of the
  // properties below. Every one of these bindings therefore resolved to
  // undefined and the tooltip reported "Unable to assign [undefined] to
  // QColor" four times over, drawing with Qt's defaults instead of the theme.
  // Naming the tooltip is what makes the bindings reach it.
  id: panel

  property color panelForeground: Color.tooltip.text
  property color panelBackground: Color.tooltip.background
  property color panelBorder: Color.tooltip.border
  property string fontFamily: Style.font.family
  property real fontSize: Style.font.bodySmall

  contentItem: Text {
    text: panel.text
    color: panel.panelForeground
    font.family: panel.fontFamily
    font.pixelSize: panel.fontSize
  }

  background: Rectangle {
    color: panel.panelBackground
    radius: Style.cornerRadius
    border.color: panel.panelBorder
  }
}
