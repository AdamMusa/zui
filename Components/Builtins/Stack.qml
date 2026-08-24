import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Item {
  required property var renderer
      implicitWidth: childrenRect.width
      implicitHeight: childrenRect.height
      Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
    }
