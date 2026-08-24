import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

ZuiControls.ConfirmDialog {
  required property var renderer
      opened: renderer.prop("opened", false) === true; message: String(renderer.prop("message", ""))
      cancelText: String(renderer.prop("cancel_text", "Cancel")); confirmText: String(renderer.prop("confirm_text", "Confirm"))
      selectedIndex: Number(renderer.prop("selected_index", 1)); visible: renderer.prop("visible", true) !== false
      background: renderer.prop("background", Color.background); foreground: renderer.prop("foreground", renderer.foreground)
      scrim: renderer.prop("scrim", Util.alpha(Color.background, 0.7)); selectedBackground: renderer.prop("selected_background", Util.alpha(renderer.foreground, 0.08))
      selectedText: renderer.prop("selected_text", Color.accent); fontFamily: String(renderer.prop("font_family", renderer.fontFamily))
      cornerRadius: Number(renderer.prop("corner_radius", Style.cornerRadius))
      onCanceled: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "cancel", {})
      onConfirmed: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "confirm", {})
    }
