import QtQuick
import "../Theme"

Item {
  id: root
  property string text: ""
  property string iconText: ""
  property string tooltipText: ""
  property bool selected: false
  property bool active: false
  property bool hasCursor: false
  property bool focusable: true
  property bool bordered: true
  property color foreground: Color.foreground
  property color background: "transparent"
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property string iconFontFamily: Fonts.iconFamily
  property real fontSize: Style.font.body
  property real iconSize: Style.font.icon
  property real iconRotation: 0
  property bool iconSpinning: false
  property real horizontalPadding: Style.spacing.controlPaddingX
  property real verticalPadding: Style.spacing.controlPaddingY
  property bool leftAlign: false
  property color tooltipBackground: Color.tooltip.background
  property color tooltipForeground: Color.tooltip.text
  property color tooltipBorder: Color.tooltip.border
  signal clicked()
  signal rightClicked()
  signal hovered(bool value)

  activeFocusOnTab: focusable
  implicitWidth: content.implicitWidth + horizontalPadding * 2
  implicitHeight: Math.max(Style.spacing.controlHeight, content.implicitHeight + verticalPadding * 2)

  Rectangle {
    anchors.fill: parent
    radius: Style.cornerRadius
    color: root.selected || root.active ? root.accent : root.background
    border.width: root.bordered ? Style.normalBorderWidth : 0
    border.color: root.active || root.selected ? root.accent : Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.3)
    opacity: mouse.pressed ? 0.78 : (mouse.containsMouse ? 0.9 : 1)
  }

  Row {
    id: content
    anchors.verticalCenter: parent.verticalCenter
    anchors.left: root.leftAlign ? parent.left : undefined
    anchors.leftMargin: root.horizontalPadding
    anchors.horizontalCenter: root.leftAlign ? undefined : parent.horizontalCenter
    spacing: root.iconText !== "" && root.text !== "" ? Style.spacing.controlGap : 0
    Text {
      visible: root.iconText !== ""
      text: root.iconText
      color: root.selected || root.active ? Color.background : root.foreground
      font.family: root.iconFontFamily
      font.pixelSize: root.iconSize
      rotation: root.iconRotation
    }
    Text {
      visible: root.text !== ""
      text: root.text
      color: root.selected || root.active ? Color.background : root.foreground
      font.family: root.fontFamily
      font.pixelSize: root.fontSize
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: root.hasCursor ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: function(event) { event.button === Qt.RightButton ? root.rightClicked() : root.clicked() }
    onContainsMouseChanged: root.hovered(containsMouse)
  }
}
