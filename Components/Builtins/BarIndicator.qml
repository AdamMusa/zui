import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

ZuiControls.BarIndicator {
  required property var renderer
      active: renderer.prop("active", false) === true
      activeText: renderer.iconGlyph(renderer.prop("active_icon", ""))
      inactiveText: renderer.iconGlyph(renderer.prop("inactive_icon", renderer.prop("active_icon", "")))
      activeTooltipText: renderer.escapeAutoText(renderer.prop("active_tooltip", ""))
      inactiveTooltipText: renderer.escapeAutoText(renderer.prop("inactive_tooltip", renderer.prop("active_tooltip", "")))
      indicatorBlock: String(renderer.prop("indicator_block", "single"))
      foreground: renderer.prop("foreground", renderer.foreground)
      activeColor: renderer.prop("active_color", Color.accent)
      fontFamily: renderer.iconFontFamilyFor(active
        ? renderer.prop("active_icon", "")
        : renderer.prop("inactive_icon", renderer.prop("active_icon", "")))
      fontSize: Number(renderer.prop("font_size", Style.font.caption))
      onPressed: function(button) {
        var eventName = button === Qt.RightButton ? "right_click" : (button === Qt.MiddleButton ? "middle_click" : "click")
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, eventName, { button: button })
      }
      onWheelMoved: function(delta) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "wheel", { delta: delta }) }
    }
