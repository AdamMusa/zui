import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Item {
  required property var renderer
      readonly property real aspect: Math.max(0.000001, Number(renderer.prop("ratio", 1)))
      readonly property var requestedWidth: renderer.prop("width", null)
      readonly property var requestedHeight: renderer.prop("height", null)
      readonly property real naturalWidth: aspectContent.implicitWidth
      readonly property real naturalHeight: aspectContent.implicitHeight
      implicitWidth: requestedWidth !== null
        ? Number(requestedWidth)
        : (requestedHeight !== null ? Number(requestedHeight) * aspect : Math.max(naturalWidth, naturalHeight * aspect))
      implicitHeight: requestedHeight !== null
        ? Number(requestedHeight)
        : (requestedWidth !== null ? Number(requestedWidth) / aspect : implicitWidth / aspect)
      clip: renderer.prop("clip", false) === true
      Item {
        id: aspectContent
        anchors.centerIn: parent
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
        Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
      }
    }
