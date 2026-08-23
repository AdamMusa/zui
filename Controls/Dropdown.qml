import QtQuick
import QtQuick.Controls as QQC
import "../Theme"

Column {
  id: root

  property string label: ""
  property string value: ""
  property var options: []
  property color foreground: Color.foreground
  property color background: Color.popups.background
  property color popupBorder: Color.popups.border
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property real rowHeight: Style.spacing.controlHeight
  property real popupRowHeight: Style.spacing.popupRowHeight
  property bool showLabel: true
  property bool hasCursor: false

  signal changed(string value)
  signal optionHovered(var value)

  spacing: Style.spacing.xs

  Text {
    visible: root.showLabel && root.label !== ""
    text: root.label
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
  }

  QQC.ComboBox {
    id: combo

    width: root.width
    height: root.rowHeight
    model: root.options
    currentIndex: Math.max(0, root.options.indexOf(root.value))
    hoverEnabled: true
    onActivated: root.changed(String(currentText))
    onHoveredChanged: root.optionHovered(hovered)

    contentItem: Text {
      text: combo.displayText
      color: root.foreground
      font.family: root.fontFamily
      verticalAlignment: Text.AlignVCenter
      leftPadding: Style.spacing.controlPaddingX
    }

    background: Rectangle {
      color: root.background
      radius: Style.cornerRadius
      border.color: combo.activeFocus ? root.accent : root.popupBorder
    }
  }
}
