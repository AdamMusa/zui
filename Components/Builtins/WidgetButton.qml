import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

ZuiControls.WidgetButton {
  required property var renderer
      text: renderer.escapeAutoText(renderer.prop("text", "")); tooltipText: renderer.escapeAutoText(renderer.prop("tooltip", "")); active: renderer.prop("active", false) === true
      dimmed: renderer.prop("dimmed", false) === true; concealed: renderer.prop("concealed", false) === true
      interactive: renderer.prop("interactive", true) !== false; pressable: renderer.prop("pressable", true) !== false
      fontFamily: String(renderer.prop("font_family", renderer.fontFamily)); fontSize: Number(renderer.prop("font_size", Style.font.body))
      foreground: renderer.prop("foreground", renderer.foreground); activeColor: renderer.prop("active_color", Color.urgent)
      horizontalMargin: Number(renderer.prop("horizontal_margin", 8.5)); verticalPadding: Number(renderer.prop("vertical_padding", 6))
      fixedWidth: Number(renderer.prop("fixed_width", -1)); fixedHeight: Number(renderer.prop("fixed_height", -1)); textRotation: Number(renderer.prop("text_rotation", 0))
      keepSpace: renderer.prop("keep_space", false) === true; useActiveColor: renderer.prop("use_active_color", true) !== false
      maintainIndicatorReveal: renderer.prop("maintain_indicator_reveal", false) === true
      labelVisible: renderer.prop("label_visible", true) !== false; hasVisualContent: renderer.prop("has_visual_content", text !== "") === true
      onPressed: function(button) {
        var eventName = button === Qt.RightButton ? "right_click" : (button === Qt.MiddleButton ? "middle_click" : "click")
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, eventName, { button: button })
      }
      onWheelMoved: function(delta) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "wheel", { delta: delta }) }
    }
