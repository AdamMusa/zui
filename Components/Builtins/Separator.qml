import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"
import "../../Controls" as ZuiControls

ZuiControls.PanelSeparator {
  required property var renderer
  foreground: renderer.foreground
  strength: Number(renderer.prop("strength", 0.12))
}
