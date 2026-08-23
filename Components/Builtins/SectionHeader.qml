import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import QtMultimedia
import QtQuick.VectorImage
import "../../Theme"
import "../../Controls" as ZuiControls

ZuiControls.PanelSectionHeader {
  required property var renderer
  text: renderer.escapeAutoText(renderer.prop("text", ""))
  foreground: renderer.foreground
  fontFamily: renderer.fontFamily
}
