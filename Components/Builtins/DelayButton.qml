import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

QQC.DelayButton {
  required property var renderer
      id: nativeDelayButton
      text: String(renderer.prop("text", ""))
      delay: Number(renderer.prop("delay", 1000))
      enabled: renderer.prop("enabled", true) !== false
      implicitWidth: Number(renderer.prop("width", 140))
      implicitHeight: Number(renderer.prop("height", 40))
      background: Rectangle {
        radius: Style.cornerRadius
        color: renderer.prop("background", Color.popups.background)
        border.width: Style.normalBorderWidth
        border.color: nativeDelayButton.activeFocus ? renderer.prop("accent", Color.accent) : renderer.prop("foreground", renderer.foreground)
        Rectangle {
          width: parent.width * nativeDelayButton.progress
          height: parent.height
          radius: parent.radius
          color: renderer.prop("progress_background", renderer.prop("accent", Color.accent))
          opacity: 0.45
        }
      }
      contentItem: Text {
        text: nativeDelayButton.text
        textFormat: Text.PlainText
        color: renderer.prop("foreground", renderer.foreground)
        font.family: String(renderer.prop("font_family", renderer.fontFamily))
        font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
      onActivated: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "activate", {})
      onProgressChanged: {
        if (renderer.subscribed("progress")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "progress", { value: progress })
      }
      onPressed: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "press", {})
      onReleased: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "release", {})
      onCanceled: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "cancel", {})
    }
