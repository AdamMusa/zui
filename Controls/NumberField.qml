import QtQuick
import QtQuick.Controls as QQC
import "../Theme"

Item {
  id: root
  property string label: ""
  property real value: 0
  property real from: 0
  property real to: 100
  property real stepSize: 1
  property color foreground: Color.foreground
  property color accent: Color.accent
  property string fontFamily: Style.font.family
  property real fontSize: Style.font.body
  property real fieldWidth: 108
  property bool hasCursor: false
  signal modified(real value)
  signal hovered(bool value)
  implicitWidth: labelText.implicitWidth + fieldWidth + Style.spacing.controlGap
  implicitHeight: spin.implicitHeight
  Row { spacing: Style.spacing.controlGap; Text { id: labelText; anchors.verticalCenter: parent.verticalCenter; text: root.label; color: root.foreground; font.family: root.fontFamily; font.pixelSize: root.fontSize } QQC.SpinBox { id: spin; width: root.fieldWidth; from: Math.round(root.from / root.stepSize); to: Math.round(root.to / root.stepSize); value: Math.round(root.value / root.stepSize); editable: true; onValueModified: root.modified(value * root.stepSize) } }
  HoverHandler { onHoveredChanged: root.hovered(hovered) }
}
