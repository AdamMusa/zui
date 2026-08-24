import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Item {
  required property var renderer
      implicitWidth: Number(renderer.prop("width", fittedContent.implicitWidth))
      implicitHeight: Number(renderer.prop("height", fittedContent.implicitHeight))
      clip: renderer.prop("clip", true) !== false

      readonly property real sourceWidth: Math.max(0.000001, fittedContent.implicitWidth)
      readonly property real sourceHeight: Math.max(0.000001, fittedContent.implicitHeight)
      readonly property real availableXScale: width / sourceWidth
      readonly property real availableYScale: height / sourceHeight
      readonly property string fitMode: String(renderer.prop("fit", "contain"))
      readonly property real fittedXScale: fitMode === "fill" ? availableXScale
        : (fitMode === "none" ? 1
        : (fitMode === "cover" ? Math.max(availableXScale, availableYScale)
        : (fitMode === "scale_down" ? Math.min(1, Math.min(availableXScale, availableYScale))
        : Math.min(availableXScale, availableYScale))))
      readonly property real fittedYScale: fitMode === "fill" ? availableYScale : fittedXScale
      readonly property string contentAlignment: String(renderer.prop("alignment", "center"))

      Item {
        id: fittedContent
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
        x: contentAlignment.indexOf("left") >= 0 || contentAlignment === "start" ? 0
          : (contentAlignment.indexOf("right") >= 0 || contentAlignment === "end" ? parent.width - implicitWidth * fittedXScale : (parent.width - implicitWidth * fittedXScale) / 2)
        y: contentAlignment.indexOf("top") >= 0 || contentAlignment === "start" ? 0
          : (contentAlignment.indexOf("bottom") >= 0 || contentAlignment === "end" ? parent.height - implicitHeight * fittedYScale : (parent.height - implicitHeight * fittedYScale) / 2)
        transformOrigin: Item.TopLeft
        transform: Scale { xScale: fittedXScale; yScale: fittedYScale }
        Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
      }
    }
