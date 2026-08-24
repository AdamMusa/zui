import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Flow {
  required property var renderer
      width: Number(renderer.prop("width", 420))
      height: renderer.prop("height", null) === null ? childrenRect.height : Number(renderer.prop("height", childrenRect.height))
      spacing: Number(renderer.prop("spacing", Style.spacing.controlGap))
      flow: String(renderer.prop("orientation", "horizontal")) === "vertical" ? Flow.TopToBottom : Flow.LeftToRight
      Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
    }
