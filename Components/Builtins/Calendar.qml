import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

Rectangle {
  id: calendarRoot
  property var renderer: null
  property date shownDate: requestedDate()
  implicitWidth: Number(renderer ? renderer.prop("width", 360) : 360)
  implicitHeight: Number(renderer ? renderer.prop("height", 360) : 360)
  color: renderer ? renderer.prop("background", Color.background) : Color.background
  radius: Number(renderer ? renderer.prop("radius", Style.cornerRadius) : Style.cornerRadius)
  border.color: renderer ? renderer.prop("border_color", "transparent") : "transparent"

  function parseDate(value) {
    var parts = String(value || "").split("-")
    return parts.length === 3 ? new Date(Number(parts[0]), Number(parts[1]) - 1, Number(parts[2])) : new Date()
  }
  function requestedDate() { var value=renderer?String(renderer.prop("date","")):"";if(value!=="")return parseDate(value);var now=new Date();return new Date(Number(renderer?renderer.prop("year",now.getFullYear()):now.getFullYear()),Number(renderer?renderer.prop("month",now.getMonth()+1):now.getMonth()+1)-1,now.getDate()) }
  function dateAllowed(value) { var minimum=renderer?String(renderer.prop("minimum","")):"";var maximum=renderer?String(renderer.prop("maximum","")):"";var text=dateText(value);return (minimum===""||text>=minimum)&&(maximum===""||text<=maximum) }
  function dateText(value) { return Qt.formatDate(value, "yyyy-MM-dd") }
  function changeMonth(delta) {
    shownDate = new Date(shownDate.getFullYear(), shownDate.getMonth() + delta, 1)
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "navigate", { month: shownDate.getMonth() + 1, year: shownDate.getFullYear() })
  }
  Column {
    anchors.fill: parent; anchors.margins: 8; spacing: 4
    Rectangle {
      width: parent.width; height: 40; visible: renderer.prop("show_navigation", true) !== false
      color: renderer.prop("header_background", "transparent")
      QQC.ToolButton { anchors.left: parent.left; text: "‹"; onClicked: calendarRoot.changeMonth(-1) }
      Text { anchors.fill: parent; anchors.leftMargin: 40; anchors.rightMargin: 40; text: Qt.formatDate(calendarRoot.shownDate, "MMMM yyyy"); color: renderer.prop("foreground", renderer.foreground); font.family: renderer.prop("font_family", renderer.fontFamily); font.pixelSize: Number(renderer.prop("font_size", Style.font.body)); font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
      QQC.ToolButton { anchors.right: parent.right; text: "›"; onClicked: calendarRoot.changeMonth(1) }
    }
    Item {
      width: parent.width; height: parent.height - y
      readonly property real weekWidth: renderer.prop("show_week_numbers", false) === true ? 36 : 0
      QQC.DayOfWeekRow { x: parent.weekWidth; width: parent.width - parent.weekWidth; height: 32; locale: Qt.locale(String(renderer.prop("locale", Qt.locale().name))) }
      QQC.WeekNumberColumn { visible: parent.weekWidth > 0; width: parent.weekWidth; y: 32; height: parent.height - 32; month: calendarRoot.shownDate.getMonth(); year: calendarRoot.shownDate.getFullYear(); locale: Qt.locale(String(renderer.prop("locale", Qt.locale().name))); delegate: Text { required property var model; text: model.weekNumber; color: renderer.prop("muted", Color.muted); horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter } }
      QQC.MonthGrid {
        id: nativeGrid
        x: parent.weekWidth; y: 32; width: parent.width - parent.weekWidth; height: parent.height - 32
        month: calendarRoot.shownDate.getMonth(); year: calendarRoot.shownDate.getFullYear(); locale: Qt.locale(String(renderer.prop("locale", Qt.locale().name)))
        delegate: Text {
          required property var model
          horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
          text: model.day; opacity: calendarRoot.dateAllowed(model.date) ? 1 : 0.35; color: model.month === nativeGrid.month ? renderer.prop("foreground", renderer.foreground) : renderer.prop("muted", Color.muted)
          font.family: renderer.prop("font_family", renderer.fontFamily); font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
          Rectangle { anchors.fill: parent; z: -1; radius: width / 2; color: calendarRoot.dateText(model.date) === calendarRoot.dateText(calendarRoot.shownDate) ? renderer.prop("selected_background", renderer.prop("accent", Color.accent)) : (calendarRoot.dateText(model.date) === calendarRoot.dateText(new Date()) ? renderer.prop("today_background", Color.popups.background) : "transparent") }
        }
        onClicked: function(date) { if(!calendarRoot.dateAllowed(date))return;calendarRoot.shownDate = date; var payload = { value: calendarRoot.dateText(date) }; renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "input", payload); renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", payload) }
      }
    }
  }
}
