import QtQuick
import QtQuick.Controls as QQC

Item {
  id: root
  required property var renderer
  visible: false
  function parsedDate(name, fallback) {
    var value = String(renderer.prop(name, ""))
    if (value === "") return fallback
    var result = new Date(value)
    return isNaN(result.getTime()) ? fallback : result
  }
  function publish() {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", {
      count: nativeModel.count,
      from: nativeModel.from.toISOString(),
      to: nativeModel.to.toISOString()
    })
  }
  QQC.CalendarModel {
    id: nativeModel
    from: root.parsedDate("from", new Date(1970, 0, 1))
    to: root.parsedDate("to", new Date(2100, 11, 31))
    onCountChanged: root.publish()
  }
  Component.onCompleted: publish()
}
