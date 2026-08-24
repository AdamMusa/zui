import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

ZuiControls.BarIconButton {
  required property var renderer
      text: renderer.iconGlyph(renderer.prop("icon", ""))
      tooltipText: renderer.escapeAutoText(renderer.prop("tooltip", ""))
      active: renderer.prop("active", false) === true
      foreground: renderer.prop("foreground", renderer.foreground)
      activeColor: renderer.prop("active_color", Color.accent)
      slotSize: Number(renderer.prop("slot_size", Style.bar.iconSlot))
      opticalSize: Number(renderer.prop("optical_size", Style.bar.iconCanvas))
      fontFamily: renderer.iconFontFamilyFor(renderer.prop("icon", ""))
      fontSize: Number(renderer.prop("font_size", Style.bar.iconFont))
      textRotation: Number(renderer.prop("text_rotation", 0))
      keepSpace: renderer.prop("keep_space", false) === true
      dimmed: renderer.prop("dimmed", false) === true
      concealed: renderer.prop("concealed", false) === true
      interactive: renderer.prop("interactive", true) !== false
      onPressed: function(button) {
        var eventName = button === Qt.RightButton ? "right_click" : (button === Qt.MiddleButton ? "middle_click" : "click")
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, eventName, { button: button })
      }
      onWheelMoved: function(delta) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "wheel", { delta: delta }) }
    }
