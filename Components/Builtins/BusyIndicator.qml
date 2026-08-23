import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.BusyIndicator {
  id: busyRoot

  required property var renderer

  running: renderer.prop("running", true) !== false
  implicitWidth: Number(renderer.prop("width", 48))
  implicitHeight: Number(renderer.prop("height", 48))
  enabled: renderer.prop("enabled", true) !== false
  opacity: Number(renderer.prop("opacity", enabled ? 1 : 0.5))
  palette.highlight: renderer.prop("color", Color.accent)
  palette.accent: renderer.prop("color", Color.accent)
  Accessible.name: String(renderer.prop("accessible_name", "Loading"))
  Accessible.role: Accessible.Indicator

  onRunningChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    "running_change", { value: running })
  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
}
