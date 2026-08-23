import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.WeekNumberColumn {
  id: weekRoot
  property var renderer: null
  implicitWidth: Number(renderer ? renderer.prop("width", 44) : 44); implicitHeight: Number(renderer ? renderer.prop("height", 280) : 280)
  month: Number(renderer ? renderer.prop("month", new Date().getMonth() + 1) : new Date().getMonth() + 1) - 1
  year: Number(renderer ? renderer.prop("year", new Date().getFullYear()) : new Date().getFullYear())
  locale: Qt.locale(String(renderer ? renderer.prop("locale", Qt.locale().name) : Qt.locale().name))
  delegate: Rectangle { required property var model; color: renderer.prop("background", "transparent"); Text { anchors.fill: parent; text: model.weekNumber; color: renderer.prop("foreground", renderer.prop("muted", renderer.foreground)); font.family: renderer.prop("font_family", renderer.fontFamily); font.pixelSize: Number(renderer.prop("font_size", Style.font.body)); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter } TapHandler { onTapped: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "week_click", { value: model.weekNumber }) } }
}
