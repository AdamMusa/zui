import QtQuick
import "../Theme"

Item {
  id: root
  property bool opened: false
  property string message: ""
  property string cancelText: "Cancel"
  property string confirmText: "Confirm"
  property int selectedIndex: 1
  property color background: Color.background
  property color foreground: Color.foreground
  property color scrim: Qt.rgba(0, 0, 0, 0.7)
  property color selectedBackground: Qt.rgba(1, 1, 1, 0.08)
  property color selectedText: Color.accent
  property string fontFamily: Style.font.family
  property real cornerRadius: Style.cornerRadius
  signal canceled()
  signal confirmed()
  implicitWidth: 420
  implicitHeight: panel.implicitHeight
  visible: opened
  Rectangle { id: panel; anchors.fill: parent; implicitHeight: content.implicitHeight + Style.spacing.xl * 2; color: root.background; radius: root.cornerRadius; border.color: Color.popups.border }
  Column {
    id: content
    anchors.fill: parent
    anchors.margins: Style.spacing.xl
    spacing: Style.spacing.lg
    Text { width: parent.width; text: root.message; color: root.foreground; font.family: root.fontFamily; wrapMode: Text.WordWrap }
    Row {
      anchors.right: parent.right
      spacing: Style.spacing.sm
      Button { text: root.cancelText; onClicked: root.canceled() }
      Button { text: root.confirmText; active: true; onClicked: root.confirmed() }
    }
  }
}
