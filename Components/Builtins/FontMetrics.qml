import QtQuick
import "../../Theme"

Item {
  id: metricsRoot
  required property var renderer
  property string handledRequestKey: ""
  implicitWidth: 0
  implicitHeight: 0

  function elideMode() {
    var requested = String(renderer.prop("elide", "right"))
    if (requested === "left") return Qt.ElideLeft
    if (requested === "middle") return Qt.ElideMiddle
    if (requested === "none") return Qt.ElideNone
    return Qt.ElideRight
  }

  function requestKey() {
    return [String(renderer.prop("font_family", "")), String(renderer.prop("font_size", "")),
      String(renderer.prop("bold", false)), String(renderer.prop("italic", false)),
      String(renderer.prop("letter_spacing", 0)), String(renderer.prop("word_spacing", 0)),
      String(renderer.prop("text", "")), String(renderer.prop("elide", "right")),
      String(renderer.prop("elide_width", 0))].join("\u001f")
  }

  function publish() {
    var key = requestKey()
    if (key === handledRequestKey) return
    handledRequestKey = key
    var sample = String(renderer.prop("text", ""))
    var bounding = nativeMetrics.boundingRect(sample)
    var tight = nativeMetrics.tightBoundingRect(sample)
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "metrics", {
      ascent: nativeMetrics.ascent, descent: nativeMetrics.descent,
      height: nativeMetrics.height, leading: nativeMetrics.leading,
      line_spacing: nativeMetrics.lineSpacing,
      minimum_left_bearing: nativeMetrics.minimumLeftBearing,
      minimum_right_bearing: nativeMetrics.minimumRightBearing,
      maximum_character_width: nativeMetrics.maximumCharacterWidth,
      x_height: nativeMetrics.xHeight,
      average_character_width: nativeMetrics.averageCharacterWidth,
      underline_position: nativeMetrics.underlinePosition,
      overline_position: nativeMetrics.overlinePosition,
      strike_out_position: nativeMetrics.strikeOutPosition,
      line_width: nativeMetrics.lineWidth,
      advance_width: nativeMetrics.advanceWidth(sample),
      bounding_rect: { x: bounding.x, y: bounding.y, width: bounding.width, height: bounding.height },
      tight_bounding_rect: { x: tight.x, y: tight.y, width: tight.width, height: tight.height },
      elided_text: nativeMetrics.elidedText(sample, metricsRoot.elideMode(),
                                            Number(renderer.prop("elide_width", 0)))
    })
  }

  FontMetrics {
    id: nativeMetrics
    font.family: String(renderer.prop("font_family", renderer.fontFamily))
    font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
    font.bold: renderer.prop("bold", false) === true
    font.italic: renderer.prop("italic", false) === true
    font.letterSpacing: Number(renderer.prop("letter_spacing", 0))
    font.wordSpacing: Number(renderer.prop("word_spacing", 0))
  }

  Component.onCompleted: publish()
  Connections { target: renderer; function onNodeChanged() { metricsRoot.publish() } }
}
