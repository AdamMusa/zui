import QtQuick
import QtQuick.Controls as QQC
import "../Theme"

QQC.TextField {
  id: root
  property bool password: false
  property color foreground: Color.foreground
  property color accent: Color.accent
  property color selectionTint: Style.selectionFillFor(foreground, accent)
  property real horizontalPadding: Style.spacing.controlPaddingX
  property real verticalPadding: Style.spacing.inputPaddingY
  property bool hasCursor: false
  color: foreground
  selectionColor: selectionTint
  selectedTextColor: foreground
  echoMode: password ? TextInput.Password : TextInput.Normal
  leftPadding: horizontalPadding
  rightPadding: horizontalPadding
  topPadding: verticalPadding
  bottomPadding: verticalPadding
  font.family: Style.font.family
  font.pixelSize: Style.font.body
  background: Rectangle { color: Color.popups.background; radius: Style.cornerRadius; border.color: root.activeFocus ? root.accent : Color.popups.border; border.width: 1 }
}
