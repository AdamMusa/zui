import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Item {
  required property var renderer
      implicitWidth: 0
      implicitHeight: 0
      TextMetrics {
        id: nativeTextMetrics
        text: String(renderer.prop("text", ""))
        font.family: String(renderer.prop("font_family", renderer.fontFamily))
        font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
        font.bold: renderer.prop("bold", false) === true
        font.italic: renderer.prop("italic", false) === true
        font.letterSpacing: Number(renderer.prop("letter_spacing", 0))
        font.wordSpacing: Number(renderer.prop("word_spacing", 0))
        elide: {
          var mode = String(renderer.prop("elide", "none"))
          if (mode === "left") return Text.ElideLeft
          if (mode === "middle") return Text.ElideMiddle
          if (mode === "right") return Text.ElideRight
          return Text.ElideNone
        }
        elideWidth: Number(renderer.prop("elide_width", 0))
        onMetricsChanged: {
          if (!renderer.subscribed("metrics")) return
          renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "metrics", {
            width: width, height: height, advance_width: advanceWidth, elided_text: elidedText,
            bounding_rect: { x: boundingRect.x, y: boundingRect.y, width: boundingRect.width, height: boundingRect.height },
            tight_bounding_rect: { x: tightBoundingRect.x, y: tightBoundingRect.y, width: tightBoundingRect.width, height: tightBoundingRect.height }
          })
        }
      }
    }
