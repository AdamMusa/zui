import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

ZuiControls.PanelActionButton {
  required property var renderer
      iconText: renderer.iconGlyph(renderer.prop("icon", "")); tooltipText: renderer.escapeAutoText(renderer.prop("tooltip", ""))
      bordered: renderer.prop("bordered", false) === true; focusable: renderer.prop("focusable", false) === true
      hasCursor: renderer.prop("cursor", false) === true
      size: Number(renderer.prop("size", 28)); foreground: renderer.prop("foreground", renderer.foreground)
      hoverColor: renderer.prop("hover_color", foreground); fontFamily: renderer.iconFontFamilyFor(renderer.prop("icon", ""))
      fontSize: Number(renderer.prop("font_size", Style.font.icon))
      onClicked: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", {})
      onHovered: function(value) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", { value: value }) }
    }
