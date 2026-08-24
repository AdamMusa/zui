import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

ZuiControls.BorderOverlay {
  required property var renderer
      width: Number(renderer.prop("width", 120))
      height: Number(renderer.prop("height", 80))
      radius: Number(renderer.prop("radius", Style.cornerRadius))
      borderSpec: {
        var colors = renderer.prop("gradient_colors", [])
        if (Array.isArray(colors) && colors.length > 1) {
          return {
            color: colors[0],
            widths: Border.flat(colors[0], renderer.prop("width_spec", Style.normalBorderWidth)).widths,
            gradient: { colors: colors, angle: Number(renderer.prop("gradient_angle", 0)), enabled: true }
          }
        }
        return Border.flat(renderer.prop("color", renderer.foreground), renderer.prop("width_spec", Style.normalBorderWidth))
      }
    }
