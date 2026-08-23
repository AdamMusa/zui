import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.DayOfWeekRow {
  id: dayRoot
  property var renderer: null
  implicitWidth: Number(renderer ? renderer.prop("width", 320) : 320); implicitHeight: Number(renderer ? renderer.prop("height", 36) : 36)
  locale: Qt.locale(String(renderer ? renderer.prop("locale", Qt.locale().name) : Qt.locale().name))
  delegate: Rectangle { required property var model; color: renderer.prop("background", "transparent"); Text { anchors.fill: parent; text: model.shortName; color: renderer.prop("foreground", renderer.prop("muted", renderer.foreground)); font.family: renderer.prop("font_family", renderer.fontFamily); font.pixelSize: Number(renderer.prop("font_size", Style.font.body)); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter } TapHandler { onTapped: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "day_click", { day: model.day, name: model.longName }) } }
}
