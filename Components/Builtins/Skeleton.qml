import QtQuick
import "../../Theme"

Item {
  id: skeletonRoot

  required property var renderer
  readonly property string variant: String(renderer.prop("variant", "rectangle"))
  readonly property int lineCount: variant === "text"
    ? Math.max(1, Number(renderer.prop("lines", 3))) : 1
  readonly property real lineHeight: variant === "text"
    ? Number(renderer.prop("line_height", 14)) : Number(renderer.prop("height", 72))
  readonly property real lineSpacing: Number(renderer.prop("spacing", Style.spacing.sm))
  readonly property color baseColor: renderer.prop("base_color",
    Qt.rgba(renderer.foreground.r, renderer.foreground.g, renderer.foreground.b, 0.12))
  readonly property color highlightColor: renderer.prop("highlight_color",
    Qt.rgba(renderer.foreground.r, renderer.foreground.g, renderer.foreground.b, 0.28))
  readonly property bool shimmerRunning: renderer.prop("animated", true) !== false
    && visible && enabled
  property real shimmerProgress: -1

  implicitWidth: Number(renderer.prop("width", variant === "circle" ? 64 : 320))
  implicitHeight: variant === "text"
    ? lineCount * lineHeight + Math.max(0, lineCount - 1) * lineSpacing
    : Number(renderer.prop("height", variant === "circle" ? implicitWidth : 72))
  enabled: renderer.prop("enabled", true) !== false
  opacity: Number(renderer.prop("opacity", enabled ? 1 : 0.5))
  Accessible.name: String(renderer.prop("accessible_name", "Loading content"))
  Accessible.role: Accessible.Indicator

  Repeater {
    model: skeletonRoot.lineCount

    Rectangle {
      required property int index
      x: 0
      y: index * (skeletonRoot.lineHeight + skeletonRoot.lineSpacing)
      width: skeletonRoot.variant === "text" && index === skeletonRoot.lineCount - 1
        ? skeletonRoot.width * Math.max(0, Math.min(1, Number(renderer.prop("last_line_width", 0.68))))
        : skeletonRoot.width
      height: skeletonRoot.variant === "circle" ? skeletonRoot.height : skeletonRoot.lineHeight
      radius: skeletonRoot.variant === "circle" ? Math.min(width, height) / 2
        : Number(renderer.prop("radius", Style.cornerRadius))
      color: skeletonRoot.baseColor
      clip: true

      Rectangle {
        width: Math.max(24, parent.width * 0.7)
        height: parent.height
        x: {
          var travel = parent.width + width
          var offset = skeletonRoot.shimmerProgress * travel
          return String(renderer.prop("direction", "left_to_right")) === "right_to_left"
            ? parent.width - offset : offset - width
        }
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0; color: "transparent" }
          GradientStop { position: 0.5; color: skeletonRoot.highlightColor }
          GradientStop { position: 1; color: "transparent" }
        }
      }
    }
  }

  NumberAnimation on shimmerProgress {
    from: 0
    to: 1
    duration: Number(renderer.prop("duration", 1200))
    loops: Animation.Infinite
    running: skeletonRoot.shimmerRunning
  }

  onShimmerRunningChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    "animation_change", { running: shimmerRunning })
  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
}
