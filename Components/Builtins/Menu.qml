import QtQuick
import QtQuick.Controls as QQC
import Qt.labs.qmlmodels
import "../../Theme"

QQC.Menu {
  id: menuRoot

  required property var renderer
  readonly property var menuEntries: renderer.prop("items", [])
  readonly property bool requestedOpen: renderer.prop("opened", false) === true
    && renderer.prop("visible", true) !== false

  function entryValue(entry, name, fallback) {
    return entry !== null && typeof entry === "object" && entry[name] !== undefined
      ? entry[name] : fallback
  }

  function entryLabel(entry) {
    return entry !== null && typeof entry === "object"
      ? String(entry.label === undefined ? (entry.text === undefined ? "" : entry.text) : entry.label)
      : String(entry === null ? "" : entry)
  }

  function entryPayload(index, entry, item) {
    var label = entryLabel(entry)
    return {
      index: index,
      label: label,
      value: entryValue(entry, "value", label),
      checked: item ? item.checked : false
    }
  }

  function closePolicyValue(value) {
    var names = Array.isArray(value) ? value : [value || "escape_and_outside"]
    var result = 0
    for (var index = 0; index < names.length; index++) {
      var name = String(names[index])
      if (name === "escape" || name === "escape_and_outside") result |= QQC.Popup.CloseOnEscape
      if (name === "outside" || name === "escape_and_outside") result |= QQC.Popup.CloseOnPressOutside
      if (name === "outside_parent") result |= QQC.Popup.CloseOnPressOutsideParent
      if (name === "release_outside") result |= QQC.Popup.CloseOnReleaseOutside
      if (name === "release_outside_parent") result |= QQC.Popup.CloseOnReleaseOutsideParent
    }
    return result
  }

  function syncOpenState() {
    if (requestedOpen === opened) return
    if (requestedOpen) open()
    else close()
  }

  title: String(renderer.prop("title", ""))
  x: Number(renderer.prop("x", 0))
  y: Number(renderer.prop("y", 0))
  width: Number(renderer.prop("width", 240))
  modal: renderer.prop("modal", false) === true
  closePolicy: closePolicyValue(renderer.prop("close_policy", "escape_and_outside"))
  enabled: renderer.prop("enabled", true) !== false

  background: Rectangle {
    color: renderer.prop("background", Color.background)
    radius: Number(renderer.prop("radius", Style.cornerRadius))
    border.width: String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0
    border.color: renderer.prop("border_color", "transparent")
  }

  Instantiator {
    model: Array.isArray(menuRoot.menuEntries) ? menuRoot.menuEntries : []
    delegate: DelegateChooser {
      role: "separator"

      DelegateChoice {
        roleValue: true
        QQC.MenuSeparator {}
      }

      DelegateChoice {
        QQC.MenuItem {
          required property int index
          required property var modelData
          text: menuRoot.entryLabel(modelData)
          enabled: menuRoot.enabled && menuRoot.entryValue(modelData, "enabled", true) !== false
          checkable: menuRoot.entryValue(modelData, "checkable", false) === true
          checked: menuRoot.entryValue(modelData, "checked", false) === true
          font.family: String(renderer.prop("font_family", renderer.fontFamily))
          font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
          icon.name: String(menuRoot.entryValue(modelData, "icon", ""))
          icon.source: String(menuRoot.entryValue(modelData, "icon_source", ""))
          icon.color: checked ? renderer.prop("accent", Color.accent)
            : renderer.prop("foreground", renderer.foreground)
          onClicked: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
            "trigger", menuRoot.entryPayload(index, modelData, this))
          onToggled: {
            if (renderer.subscribed("toggle"))
              renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
                "toggle", menuRoot.entryPayload(index, modelData, this))
          }
          onHighlightedChanged: {
            if (highlighted && renderer.subscribed("highlight"))
              renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
                "highlight", menuRoot.entryPayload(index, modelData, this))
          }
        }
      }
    }
    onObjectAdded: function(index, object) { menuRoot.insertItem(index, object) }
    onObjectRemoved: function(index, object) { menuRoot.removeItem(object) }
  }

  Component.onCompleted: syncOpenState()
  onRequestedOpenChanged: syncOpenState()
  onOpened: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "open", {})
  onClosed: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "close", {})
  onAboutToShow: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "about_to_show", {})
  onAboutToHide: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "about_to_hide", {})
}
