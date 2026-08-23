import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.Control {
  id: ringRoot

  required property var renderer
  readonly property real minimumValue: Number(renderer.prop("minimum", 0))
  readonly property real maximumValue: Number(renderer.prop("maximum", 1))
  readonly property real currentValue: Number(renderer.prop("value", minimumValue))
  readonly property bool indeterminate: renderer.prop("indeterminate", false) === true
  readonly property real normalizedValue: Math.max(0, Math.min(1,
    (currentValue - minimumValue) / Math.max(0.000001, maximumValue - minimumValue)))
  readonly property color ringColor: renderer.prop("color", Color.accent)
  readonly property color trackColor: renderer.prop("track_color",
    Qt.rgba(ringColor.r, ringColor.g, ringColor.b, 0.2))
  readonly property real ringThickness: Math.max(1, Number(renderer.prop("thickness", 5)))
  readonly property real startAngle: Number(renderer.prop("start_angle", -90))
  readonly property bool clockwise: renderer.prop("clockwise", true) !== false
  property real displayedProgress: indeterminate ? 0.25 : normalizedValue

  function labelText() {
    var explicitLabel = String(renderer.prop("label", ""))
    if (explicitLabel.length > 0) return explicitLabel
    var format = String(renderer.prop("label_format", "{percent}%"))
    return format
      .replace(/\{percent\}/g, String(Math.round(normalizedValue * 100)))
      .replace(/\{value\}/g, String(currentValue))
      .replace(/\{minimum\}/g, String(minimumValue))
      .replace(/\{maximum\}/g, String(maximumValue))
  }

  implicitWidth: Number(renderer.prop("width", renderer.prop("size", 64)))
  implicitHeight: Number(renderer.prop("height", renderer.prop("size", 64)))
  enabled: renderer.prop("enabled", true) !== false
  opacity: Number(renderer.prop("opacity", enabled ? 1 : 0.5))
  Accessible.name: String(renderer.prop("accessible_name", "Progress"))
  Accessible.description: labelText()
  Accessible.role: Accessible.ProgressBar

  contentItem: Item {
    Canvas {
      id: ringCanvas
      anchors.fill: parent
      anchors.margins: ringRoot.ringThickness / 2

      onPaint: {
        var context = getContext("2d")
        context.clearRect(0, 0, width, height)
        var centerX = width / 2
        var centerY = height / 2
        var radius = Math.max(0, Math.min(width, height) / 2)
        var start = ringRoot.startAngle * Math.PI / 180
        var direction = ringRoot.clockwise ? 1 : -1
        var end = start + direction * Math.PI * 2 * ringRoot.displayedProgress

        context.lineWidth = ringRoot.ringThickness
        context.lineCap = "round"
        context.strokeStyle = ringRoot.trackColor
        context.beginPath()
        context.arc(centerX, centerY, radius, 0, Math.PI * 2, false)
        context.stroke()

        context.strokeStyle = ringRoot.ringColor
        context.beginPath()
        context.arc(centerX, centerY, radius, start, end, !ringRoot.clockwise)
        context.stroke()
      }
    }

    Text {
      anchors.centerIn: parent
      visible: renderer.prop("show_label", false) === true && !ringRoot.indeterminate
      text: ringRoot.labelText()
      color: renderer.prop("foreground", renderer.foreground)
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("font_size", Style.font.caption))
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
    }
  }

  RotationAnimator {
    target: ringCanvas
    from: 0
    to: ringRoot.clockwise ? 360 : -360
    duration: Number(renderer.prop("duration", 900))
    loops: Animation.Infinite
    running: ringRoot.indeterminate && ringRoot.visible && ringRoot.enabled
  }

  Behavior on displayedProgress {
    enabled: !ringRoot.indeterminate && renderer.prop("animated", true) !== false
    NumberAnimation {
      duration: Number(renderer.prop("duration", 240))
      easing.type: renderer.easingType(renderer.prop("easing", "out_cubic"))
    }
  }

  onNormalizedValueChanged: {
    if (!indeterminate) displayedProgress = normalizedValue
    ringCanvas.requestPaint()
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "value_change", {
      value: currentValue, normalized: normalizedValue
    })
  }
  onIndeterminateChanged: {
    displayedProgress = indeterminate ? 0.25 : normalizedValue
    ringCanvas.requestPaint()
  }
  onDisplayedProgressChanged: ringCanvas.requestPaint()
  onRingColorChanged: ringCanvas.requestPaint()
  onTrackColorChanged: ringCanvas.requestPaint()
  onRingThicknessChanged: ringCanvas.requestPaint()
  onStartAngleChanged: ringCanvas.requestPaint()
  onClockwiseChanged: ringCanvas.requestPaint()
  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
}
