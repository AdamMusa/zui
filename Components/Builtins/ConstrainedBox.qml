import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Item {
  required property var renderer
      function bounded(value, minimum, maximum) {
        return Math.max(Number(minimum), Math.min(Number(maximum), Number(value)))
      }
      readonly property real naturalWidth: constrainedContent.implicitWidth
      readonly property real naturalHeight: constrainedContent.implicitHeight
      readonly property real desiredWidth: Number(renderer.prop("width", naturalWidth))
      readonly property real desiredHeight: Number(renderer.prop("height", naturalHeight))
      implicitWidth: bounded(desiredWidth, renderer.prop("min_width", 0), renderer.prop("max_width", Number.MAX_VALUE))
      implicitHeight: bounded(desiredHeight, renderer.prop("min_height", 0), renderer.prop("max_height", Number.MAX_VALUE))
      clip: renderer.prop("clip", false) === true
      Item {
        id: constrainedContent
        anchors.centerIn: parent
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
        Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
      }
    }
