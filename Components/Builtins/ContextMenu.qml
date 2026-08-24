import QtQuick
import QtQuick.Controls as QQC
import Qt.labs.qmlmodels
import "../../Theme"

Item {
  id: contextRoot

  required property var renderer
  readonly property var menuEntries: renderer.prop("items", [])
  readonly property string targetId: String(renderer.prop("target", ""))
  readonly property var targetItem: targetId.length > 0 ? renderer.findRenderedItem(targetId) : null
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
    if (requestedOpen === nativeMenu.opened) return
    if (requestedOpen) {
      nativeMenu.x = Number(renderer.prop("x", 0))
      nativeMenu.y = Number(renderer.prop("y", 0))
      nativeMenu.open()
    } else nativeMenu.close()
  }

  width: Number(renderer.prop("activation_width", 0))
  height: Number(renderer.prop("activation_height", 0))
  visible: renderer.prop("visible", true) !== false

  TapHandler {
    id: contextHandler
    parent: contextRoot.targetItem || contextRoot
    enabled: contextRoot.visible && renderer.prop("enabled", true) !== false
    acceptedButtons: Qt.RightButton
    onTapped: function(eventPoint, button) {
      var host = contextRoot.targetItem || contextRoot
      var localPoint = host === contextRoot
        ? eventPoint.position : host.mapToItem(contextRoot, eventPoint.position)
      if (renderer.subscribed("request"))
        renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "request",
          { x: localPoint.x, y: localPoint.y, button: button })
      nativeMenu.popup(localPoint)
    }
  }

  QQC.Menu {
    id: nativeMenu
    width: Number(renderer.prop("width", 240))
    modal: renderer.prop("modal", false) === true
    closePolicy: contextRoot.closePolicyValue(renderer.prop("close_policy", "escape_and_outside"))
    enabled: renderer.prop("enabled", true) !== false

    background: Rectangle {
      color: renderer.prop("background", Color.background)
      radius: Number(renderer.prop("radius", Style.cornerRadius))
      border.width: String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0
      border.color: renderer.prop("border_color", "transparent")
    }

    Instantiator {
      model: Array.isArray(contextRoot.menuEntries) ? contextRoot.menuEntries : []
      delegate: DelegateChooser {
        role: "separator"
        DelegateChoice { roleValue: true; QQC.MenuSeparator {} }
        DelegateChoice {
          QQC.MenuItem {
            required property int index
            required property var modelData
            text: contextRoot.entryLabel(modelData)
            enabled: nativeMenu.enabled && contextRoot.entryValue(modelData, "enabled", true) !== false
            checkable: contextRoot.entryValue(modelData, "checkable", false) === true
            checked: contextRoot.entryValue(modelData, "checked", false) === true
            font.family: String(renderer.prop("font_family", renderer.fontFamily))
            font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
            icon.name: String(contextRoot.entryValue(modelData, "icon", ""))
            icon.source: String(contextRoot.entryValue(modelData, "icon_source", ""))
            icon.color: checked ? renderer.prop("accent", Color.accent)
              : renderer.prop("foreground", renderer.foreground)
            onClicked: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
              "trigger", contextRoot.entryPayload(index, modelData, this))
            onToggled: {
              if (renderer.subscribed("toggle"))
                renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
                  "toggle", contextRoot.entryPayload(index, modelData, this))
            }
            onHighlightedChanged: {
              if (highlighted && renderer.subscribed("highlight"))
                renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
                  "highlight", contextRoot.entryPayload(index, modelData, this))
            }
          }
        }
      }
      onObjectAdded: function(index, object) { nativeMenu.insertItem(index, object) }
      onObjectRemoved: function(index, object) { nativeMenu.removeItem(object) }
    }

    onOpened: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "open", {})
    onClosed: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "close", {})
    onAboutToShow: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "about_to_show", {})
    onAboutToHide: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "about_to_hide", {})
  }

  Component.onCompleted: syncOpenState()
  onRequestedOpenChanged: syncOpenState()
}
