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
        id: areaCanvas
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
          if (low === null) low = Math.min.apply(Math, values)
          if (high === null) high = Math.max.apply(Math, values)
          low = Number(low); high = Number(high)
          if (high === low) { high += 1; low -= 1 }
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
          var points = []
          for (var index = 0; index < values.length; index++) {
            points.push({
              x: pad + (values.length === 1 ? chartWidth / 2 : chartWidth * index / (values.length - 1)),
              y: pad + chartHeight * (1 - (values[index] - low) / (high - low))
            })
          }
          ctx.beginPath(); ctx.moveTo(points[0].x, height - pad)
          for (var fillIndex = 0; fillIndex < points.length; fillIndex++) ctx.lineTo(points[fillIndex].x, points[fillIndex].y)
          ctx.lineTo(points[points.length - 1].x, height - pad); ctx.closePath()
          ctx.fillStyle = renderer.prop("fill_color", renderer.prop("color", Color.accent)); ctx.fill()
          ctx.beginPath(); ctx.moveTo(points[0].x, points[0].y)
          for (var lineIndex = 1; lineIndex < points.length; lineIndex++) ctx.lineTo(points[lineIndex].x, points[lineIndex].y)
          ctx.strokeStyle = renderer.prop("color", Color.accent)
          ctx.lineWidth = Number(renderer.prop("line_width", 2)); ctx.stroke()
        }
      }
      Connections { target: root; function onNodeChanged() { areaCanvas.requestPaint() } }
      MouseArea {
        anchors.fill: parent
        hoverEnabled: renderer.subscribed("hover")
        function payload(mouse) {
          var values = renderer.prop("values", [])
          if (!Array.isArray(values) || values.length === 0) return ({ index: -1 })
          var index = Math.max(0, Math.min(values.length - 1, Math.round(mouse.x / Math.max(1, width) * (values.length - 1))))
          var labels = renderer.prop("labels", [])
          return { index: index, value: values[index], label: Array.isArray(labels) ? labels[index] : null }
        }
        onClicked: function(mouse) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "select", payload(mouse)) }
        onPositionChanged: function(mouse) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", payload(mouse)) }
      }
    }
