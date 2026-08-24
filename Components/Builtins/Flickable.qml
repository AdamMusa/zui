import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Flickable {
  required property var renderer
      implicitWidth: Number(renderer.prop("width", 320))
      implicitHeight: Number(renderer.prop("height", 240))
      contentWidth: Number(renderer.prop("content_width", flickContent.implicitWidth))
      contentHeight: Number(renderer.prop("content_height", flickContent.implicitHeight))
      flickableDirection: {
        var direction = String(renderer.prop("direction", "vertical"))
        if (direction === "horizontal") return Flickable.HorizontalFlick
        if (direction === "both") return Flickable.HorizontalAndVerticalFlick
        if (direction === "auto") return Flickable.AutoFlickDirection
        return Flickable.VerticalFlick
      }
      boundsBehavior: String(renderer.prop("bounds_behavior", "stop")) === "overshoot"
        ? Flickable.DragAndOvershootBounds : Flickable.StopAtBounds
      interactive: renderer.prop("interactive", true) !== false
      clip: renderer.prop("clip", true) !== false
      function positionPayload() { return { x: contentX, y: contentY } }
      onContentXChanged: {
        if (renderer.subscribed("scroll")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "scroll", positionPayload())
      }
      onContentYChanged: {
        if (renderer.subscribed("scroll")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "scroll", positionPayload())
      }
      onMovementStarted: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "flick_start", positionPayload())
      onMovementEnded: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "flick_end", positionPayload())
      Column {
        id: flickContent
        spacing: Style.spacing.panelGap
        Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
      }
    }
