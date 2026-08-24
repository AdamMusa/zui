import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

ZuiControls.PanelToolTip {
  required property var renderer
      text: renderer.escapeAutoText(renderer.prop("text", ""))
      visible: renderer.prop("visible", false) === true
      delay: Number(renderer.prop("delay", 400))
      timeout: Number(renderer.prop("timeout", -1))
      panelForeground: renderer.prop("foreground", Color.tooltip.text)
      panelBackground: renderer.prop("background", Color.tooltip.background)
      panelBorder: renderer.prop("border", Color.tooltip.border)
      fontFamily: String(renderer.prop("font_family", renderer.fontFamily))
      fontSize: Number(renderer.prop("font_size", Style.font.bodySmall))
    }
