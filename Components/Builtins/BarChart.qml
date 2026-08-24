import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

Item {
  required property var renderer
      implicitWidth: Number(renderer.prop("width", 420))
      implicitHeight: Number(renderer.prop("height", 220))
      Canvas {
        id: barCanvas
        anchors.fill: parent
        antialiasing: true
        onPaint: {
          var ctx = getContext("2d")
          ctx.clearRect(0, 0, width, height)
          var raw = renderer.prop("values", [])
          if (!Array.isArray(raw) || raw.length === 0) return
          var values = raw.map(function(value) { return Number(value) })
          var low = renderer.prop("minimum", null)
          var high = renderer.prop("maximum", null)
          if (low === null) low = Math.min(0, Math.min.apply(Math, values))
          if (high === null) high = Math.max(0, Math.max.apply(Math, values))
          low = Number(low); high = Number(high)
          if (high === low) high = low + 1
          var pad = 10
          var chartWidth = Math.max(1, width - pad * 2)
          var chartHeight = Math.max(1, height - pad * 2)
          if (renderer.prop("show_grid", true) !== false) {
            ctx.strokeStyle = renderer.prop("grid_color", Color.muted); ctx.lineWidth = 1
            for (var grid = 0; grid <= 4; grid++) {
              var gy = pad + chartHeight * grid / 4
              ctx.beginPath(); ctx.moveTo(pad, gy); ctx.lineTo(width - pad, gy); ctx.stroke()
            }
          }
          var slot = chartWidth / values.length
          var gap = Math.max(0, Number(renderer.prop("bar_spacing", 6)))
          var colors = renderer.prop("colors", [Color.accent])
          var zeroY = pad + chartHeight * (1 - (0 - low) / (high - low))
          for (var index = 0; index < values.length; index++) {
            var valueY = pad + chartHeight * (1 - (values[index] - low) / (high - low))
            var left = pad + slot * index + gap / 2
            var top = Math.min(zeroY, valueY)
            var barHeight = Math.max(1, Math.abs(valueY - zeroY))
            ctx.fillStyle = Array.isArray(colors) && colors.length > 0 ? colors[index % colors.length] : Color.accent
            ctx.fillRect(left, top, Math.max(1, slot - gap), barHeight)
          }
        }
      }
      Connections { target: root; function onNodeChanged() { barCanvas.requestPaint() } }
      MouseArea {
        anchors.fill: parent
        hoverEnabled: renderer.subscribed("hover")
        function payload(mouse) {
          var values = renderer.prop("values", [])
          if (!Array.isArray(values) || values.length === 0) return ({ index: -1 })
          var index = Math.max(0, Math.min(values.length - 1, Math.floor(mouse.x / Math.max(1, width) * values.length)))
          var labels = renderer.prop("labels", [])
          return { index: index, value: values[index], label: Array.isArray(labels) ? labels[index] : null }
        }
        onClicked: function(mouse) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "select", payload(mouse)) }
        onPositionChanged: function(mouse) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", payload(mouse)) }
      }
    }
