import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Controls.Basic as Basic
import "../../Theme"

QQC.Button {
  id: picker

  required property var renderer
  property string externalDate: String(renderer.prop("date", ""))
  property var selectedDate: parseDate(externalDate)
  property int shownMonth: selectedDate ? selectedDate.getMonth() : new Date().getMonth()
  property int shownYear: selectedDate ? selectedDate.getFullYear() : new Date().getFullYear()

  function parseDate(value) {
    var match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(value || ""))
    if (!match) return null
    var parsed = new Date(Number(match[1]), Number(match[2]) - 1, Number(match[3]), 12, 0, 0)
    return isNaN(parsed.getTime()) ? null : parsed
  }

  function isoDate(value) {
    function pad(number) { return number < 10 ? "0" + number : String(number) }
    return value.getFullYear() + "-" + pad(value.getMonth() + 1) + "-" + pad(value.getDate())
  }

  function sameDate(left, right) {
    return left && right && left.getFullYear() === right.getFullYear()
      && left.getMonth() === right.getMonth() && left.getDate() === right.getDate()
  }

  function withinBounds(value) {
    var minimum = parseDate(renderer.prop("minimum", ""))
    var maximum = parseDate(renderer.prop("maximum", ""))
    return (!minimum || value >= minimum) && (!maximum || value <= maximum)
  }

  function navigate(offset) {
    var next = new Date(shownYear, shownMonth + offset, 1, 12, 0, 0)
    shownMonth = next.getMonth()
    shownYear = next.getFullYear()
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "navigate", {
      month: shownMonth + 1, year: shownYear
    })
  }

  onExternalDateChanged: {
    var parsed = parseDate(externalDate)
    selectedDate = parsed
    if (parsed) {
      shownMonth = parsed.getMonth()
      shownYear = parsed.getFullYear()
    }
  }

  implicitWidth: Number(renderer.prop("width", 200))
  implicitHeight: Number(renderer.prop("height", 40))
  enabled: renderer.prop("enabled", true) !== false
  onClicked: calendarPopup.open()

  background: Rectangle {
    color: renderer.prop("background", Color.popups.background)
    radius: Number(renderer.prop("radius", Style.cornerRadius))
    border.width: Style.normalBorderWidth
    border.color: picker.activeFocus
      ? renderer.prop("accent", Color.accent)
      : renderer.prop("border_color", renderer.foreground)
    opacity: picker.down ? 0.72 : 1
  }

  contentItem: Row {
    spacing: Style.spacing.controlGap
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: String(renderer.prop("label", ""))
      visible: text.length > 0
      color: renderer.prop("muted", Color.muted)
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
    }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: picker.selectedDate
        ? Qt.formatDate(picker.selectedDate, String(renderer.prop("format", "yyyy-MM-dd")))
        : String(renderer.prop("placeholder", "Choose a date"))
      color: renderer.prop("foreground", renderer.foreground)
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
    }
  }

  QQC.Popup {
    id: calendarPopup
    width: Number(renderer.prop("popup_width", 320))
    height: calendarColumn.implicitHeight + topPadding + bottomPadding
    visible: renderer.prop("opened", false) === true
    closePolicy: QQC.Popup.CloseOnEscape | QQC.Popup.CloseOnPressOutside
    padding: Style.spacing.md

    onOpened: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "open", {})
    onClosed: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "close", {})

    background: Rectangle {
      color: renderer.prop("popup_background", Color.popups.background)
      radius: Number(renderer.prop("radius", Style.cornerRadius))
      border.width: Style.normalBorderWidth
      border.color: renderer.prop("border_color", renderer.foreground)
    }

    contentItem: Column {
      id: calendarColumn
      spacing: Style.spacing.sm

      Row {
        width: parent.width
        spacing: Style.spacing.sm
        QQC.ToolButton {
          text: "‹"
          onClicked: picker.navigate(-1)
        }
        Text {
          width: parent.width - parent.spacing * 2 - 80
          height: 40
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          text: Qt.formatDate(new Date(picker.shownYear, picker.shownMonth, 1), "MMMM yyyy")
          color: renderer.prop("foreground", renderer.foreground)
          font.family: String(renderer.prop("font_family", renderer.fontFamily))
          font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
          font.bold: true
        }
        QQC.ToolButton {
          text: "›"
          onClicked: picker.navigate(1)
        }
      }

      Basic.DayOfWeekRow {
        width: parent.width
        locale: monthGrid.locale
      }

      Basic.MonthGrid {
        id: monthGrid
        width: parent.width
        month: picker.shownMonth
        year: picker.shownYear

        delegate: Rectangle {
          required property var model
          implicitWidth: 36
          implicitHeight: 32
          radius: Number(renderer.prop("radius", Style.cornerRadius)) / 2
          color: picker.sameDate(model.date, picker.selectedDate)
            ? renderer.prop("accent", Color.accent) : "transparent"
          opacity: model.month === monthGrid.month ? 1 : 0.35

          Text {
            anchors.centerIn: parent
            text: model.day
            color: picker.sameDate(model.date, picker.selectedDate)
              ? renderer.prop("background", Color.popups.background)
              : renderer.prop("foreground", renderer.foreground)
            font.family: String(renderer.prop("font_family", renderer.fontFamily))
            font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
          }
        }

        onClicked: function(date) {
          if (!picker.withinBounds(date)) return
          picker.selectedDate = date
          var value = picker.isoDate(date)
          renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "input", { value: value })
          renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: value })
          if (renderer.prop("close_on_select", true) !== false) calendarPopup.close()
        }
      }
    }
  }
}
