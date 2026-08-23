import QtQuick
import QtQuick.Controls as QQC
import "../Theme"

Item {
  id: root
  property real value: 0
  property real minimum: 0
  property real maximum: 1
  property real step: 0.05
  property bool integer: false
  property int tickCount: 0
  property color trackColor: "#33414a"
  property color fillColor: Color.accent
  property color knobColor: Color.foreground
  property real trackHeight: 4
  property real knobSize: 16
  property color tickColor: Color.background
  signal released(real value)
  signal moved(real value)
  signal rightClicked()
  implicitHeight: Math.max(knobSize, Style.spacing.controlHeight)
  QQC.Slider {
    id: slider
    anchors.fill: parent
    from: root.minimum
    to: root.maximum
    stepSize: root.step
    value: root.value
    onMoved: root.moved(root.integer ? Math.round(value) : value)
    onPressedChanged: if (!pressed) root.released(root.integer ? Math.round(value) : value)
    background: Rectangle { x: slider.leftPadding; y: slider.topPadding + slider.availableHeight / 2 - height / 2; width: slider.availableWidth; height: root.trackHeight; radius: height / 2; color: root.trackColor; Rectangle { width: slider.visualPosition * parent.width; height: parent.height; radius: parent.radius; color: root.fillColor } }
    handle: Rectangle { x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width); y: slider.topPadding + slider.availableHeight / 2 - height / 2; width: root.knobSize; height: root.knobSize; radius: width / 2; color: root.knobColor }
  }
  TapHandler { acceptedButtons: Qt.RightButton; onTapped: root.rightClicked() }
}
