import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.MonthGrid {
  id: monthRoot
  property var renderer: null
  implicitWidth: Number(renderer ? renderer.prop("width", 320) : 320); implicitHeight: Number(renderer ? renderer.prop("height", 280) : 280)
  month: Number(renderer ? renderer.prop("month", new Date().getMonth() + 1) : new Date().getMonth() + 1) - 1
  year: Number(renderer ? renderer.prop("year", new Date().getFullYear()) : new Date().getFullYear())
  locale: Qt.locale(String(renderer ? renderer.prop("locale", Qt.locale().name) : Qt.locale().name))
  function allowed(value){var text=Qt.formatDate(value,"yyyy-MM-dd");var minimum=String(renderer?renderer.prop("minimum",""):"");var maximum=String(renderer?renderer.prop("maximum",""):"");return(minimum===""||text>=minimum)&&(maximum===""||text<=maximum)}
  delegate: Text {
    required property var model
    text: model.day; opacity: monthRoot.allowed(model.date) ? 1 : 0.35; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
    color: model.month === monthRoot.month ? renderer.prop("foreground", renderer.foreground) : renderer.prop("muted", Color.muted)
    font.family: renderer.prop("font_family", renderer.fontFamily); font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
    Rectangle { anchors.fill: parent; z: -1; radius: width / 2; color: Qt.formatDate(model.date, "yyyy-MM-dd") === String(renderer.prop("selected_date", "")) ? renderer.prop("selected_background", renderer.prop("accent", Color.accent)) : (Qt.formatDate(model.date,"yyyy-MM-dd")===Qt.formatDate(new Date(),"yyyy-MM-dd")?renderer.prop("today_background",Color.popups.background):renderer.prop("background","transparent")) }
  }
  onClicked: function(date) { if(!allowed(date))return;var payload = { value: Qt.formatDate(date, "yyyy-MM-dd") }; renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", payload); renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", payload) }
  onPressed: function(date) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "press", { value: Qt.formatDate(date, "yyyy-MM-dd") }) }
  onReleased: function(date) { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "release", { value: Qt.formatDate(date, "yyyy-MM-dd") }) }
}
