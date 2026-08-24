import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Flipable {
  required property var renderer
      id: nativeFlipable
      implicitWidth: Number(renderer.prop("width", Math.max(frontFace.implicitWidth, backFace.implicitWidth)))
      implicitHeight: Number(renderer.prop("height", Math.max(frontFace.implicitHeight, backFace.implicitHeight)))
      readonly property bool flipped: renderer.prop("flipped", false) === true
      readonly property bool verticalAxis: String(renderer.prop("axis", "vertical")) === "vertical"
      front: Loader {
        id: frontFace
        source: renderer.node && renderer.node.children && renderer.node.children.length > 0 ? Qt.resolvedUrl("../../ControlNode.qml") : ""
        onLoaded: renderer.configureFace(item, renderer.node.children[0])
      }
      back: Loader {
        id: backFace
        source: renderer.node && renderer.node.children && renderer.node.children.length > 1 ? Qt.resolvedUrl("../../ControlNode.qml") : ""
        onLoaded: renderer.configureFace(item, renderer.node.children[1])
      }
      transform: Rotation {
        id: flipRotation
        origin.x: nativeFlipable.width / 2
        origin.y: nativeFlipable.height / 2
        axis.x: nativeFlipable.verticalAxis ? 0 : 1
        axis.y: nativeFlipable.verticalAxis ? 1 : 0
        axis.z: 0
        angle: nativeFlipable.flipped ? 180 : 0
        Behavior on angle {
          NumberAnimation {
            duration: Number(renderer.prop("duration", 300))
            easing.type: renderer.easingType(renderer.prop("easing", "in_out_quad"))
          }
        }
      }
      TapHandler {
        enabled: renderer.prop("interactive", false) === true
        onTapped: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: !nativeFlipable.flipped })
      }
    }
