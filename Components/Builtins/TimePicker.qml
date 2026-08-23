import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.Button {
  id: picker

  required property var renderer
  property string externalTime: String(renderer.prop("time", ""))
  property int hours: 0
  property int minutes: 0
  property int seconds: 0
  property bool syncing: false

  function pad(value) { return value < 10 ? "0" + value : String(value) }

  function parseTime(value) {
    var match = /^(\d{1,2}):(\d{2})(?::(\d{2}))?$/.exec(String(value || ""))
    if (!match) return false
    var nextHours = Number(match[1])
    var nextMinutes = Number(match[2])
    var nextSeconds = match[3] === undefined ? 0 : Number(match[3])
    if (nextHours > 23 || nextMinutes > 59 || nextSeconds > 59) return false
    syncing = true
    hours = nextHours
    minutes = nextMinutes
    seconds = nextSeconds
    syncing = false
    syncControls()
    return true
  }

  function displayedHour() {
    if (renderer.prop("use_24_hour", true) !== false) return hours
    var value = hours % 12
    return value === 0 ? 12 : value
  }

  function formattedTime() {
    var value = pad(hours) + ":" + pad(minutes)
    return renderer.prop("show_seconds", false) === true ? value + ":" + pad(seconds) : value
  }

  function displayText() {
    if (!externalTime.length) return String(renderer.prop("placeholder", "Choose a time"))
    if (renderer.prop("use_24_hour", true) !== false) return formattedTime()
    return pad(displayedHour()) + ":" + pad(minutes)
      + (renderer.prop("show_seconds", false) === true ? ":" + pad(seconds) : "")
      + (hours >= 12 ? " PM" : " AM")
  }

  function syncControls() {
    if (!hourSpin || !minuteSpin || !secondSpin || !meridiem) return
    hourSpin.value = displayedHour()
    minuteSpin.value = minutes
    secondSpin.value = seconds
    meridiem.currentIndex = hours >= 12 ? 1 : 0
  }

  function emitInput() {
    if (syncing) return
    var value = formattedTime()
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "input", { value: value })
  }

  onExternalTimeChanged: parseTime(externalTime)
  onHoursChanged: syncControls()
  onMinutesChanged: syncControls()
  onSecondsChanged: syncControls()
  Component.onCompleted: parseTime(externalTime)

  implicitWidth: Number(renderer.prop("width", 200))
  implicitHeight: Number(renderer.prop("height", 40))
  enabled: renderer.prop("enabled", true) !== false
  onClicked: timePopup.open()

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
      text: picker.displayText()
      color: renderer.prop("foreground", renderer.foreground)
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
    }
  }

  QQC.Popup {
    id: timePopup
    width: Number(renderer.prop("popup_width", 300))
    height: timeColumn.implicitHeight + topPadding + bottomPadding
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
      id: timeColumn
      spacing: Style.spacing.md

      Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Style.spacing.sm

        QQC.SpinBox {
          id: hourSpin
          from: renderer.prop("use_24_hour", true) !== false ? 0 : 1
          to: renderer.prop("use_24_hour", true) !== false ? 23 : 12
          editable: true
          onValueModified: {
            if (renderer.prop("use_24_hour", true) !== false) picker.hours = value
            else picker.hours = (value % 12) + (meridiem.currentIndex === 1 ? 12 : 0)
            picker.emitInput()
          }
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: ":"
          color: renderer.prop("foreground", renderer.foreground)
        }
        QQC.SpinBox {
          id: minuteSpin
          from: 0
          to: 59
          stepSize: Math.max(1, Number(renderer.prop("minute_step", 1)))
          editable: true
          onValueModified: {
            picker.minutes = value
            picker.emitInput()
          }
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          visible: renderer.prop("show_seconds", false) === true
          text: ":"
          color: renderer.prop("foreground", renderer.foreground)
        }
        QQC.SpinBox {
          id: secondSpin
          visible: renderer.prop("show_seconds", false) === true
          from: 0
          to: 59
          stepSize: Math.max(1, Number(renderer.prop("second_step", 1)))
          editable: true
          onValueModified: {
            picker.seconds = value
            picker.emitInput()
          }
        }
        QQC.ComboBox {
          id: meridiem
          visible: renderer.prop("use_24_hour", true) === false
          model: ["AM", "PM"]
          onActivated: {
            picker.hours = (picker.hours % 12) + (currentIndex === 1 ? 12 : 0)
            picker.emitInput()
          }
        }
      }

      Row {
        anchors.right: parent.right
        spacing: Style.spacing.sm
        QQC.Button {
          text: String(renderer.prop("cancel_text", "Cancel"))
          onClicked: {
            picker.parseTime(picker.externalTime)
            renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "reject", {
              value: picker.formattedTime()
            })
            timePopup.close()
          }
        }
        QQC.Button {
          text: String(renderer.prop("accept_text", "OK"))
          onClicked: {
            var value = picker.formattedTime()
            renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", { value: value })
            renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "accept", { value: value })
            timePopup.close()
          }
        }
      }
    }
  }
}
