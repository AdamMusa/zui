import QtQuick
import QtQuick.Controls as QQC
import Qt.labs.qmlmodels
import "../../Theme"

QQC.MenuBar {
  id: menuBarRoot

  required property var renderer
  readonly property var menuDefinitions: renderer.prop("menus", [])

  function valueOf(object, name, fallback) {
    return object !== null && typeof object === "object" && object[name] !== undefined
      ? object[name] : fallback
  }

  function labelOf(object) {
    return object !== null && typeof object === "object"
      ? String(object.label === undefined ? (object.text === undefined ? "" : object.text) : object.label)
      : String(object === null ? "" : object)
  }

  function itemPayload(menuIndex, itemIndex, definition, item) {
    var label = labelOf(definition)
    return {
      menu_index: menuIndex,
      item_index: itemIndex,
      label: label,
      value: valueOf(definition, "value", label),
      checked: item ? item.checked : false
    }
  }

  implicitWidth: Number(renderer.prop("width", 640))
  implicitHeight: Number(renderer.prop("height", 42))
  spacing: Number(renderer.prop("spacing", 0))
  padding: Number(renderer.prop("padding", Style.spacing.xs))
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false

  background: Rectangle {
    color: renderer.prop("background", Color.background)
    radius: Number(renderer.prop("radius", 0))
    border.width: String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0
    border.color: renderer.prop("border_color", "transparent")
  }

  Instantiator {
    model: Array.isArray(menuBarRoot.menuDefinitions) ? menuBarRoot.menuDefinitions : []
    delegate: QQC.Menu {
      id: nativeMenu
      required property int index
      required property var modelData
      readonly property int menuIndex: index
      readonly property var menuData: modelData
      title: String(menuBarRoot.valueOf(menuData, "title", menuBarRoot.labelOf(menuData)))
      enabled: menuBarRoot.enabled && menuBarRoot.valueOf(menuData, "enabled", true) !== false

      background: Rectangle {
        color: renderer.prop("background", Color.background)
        radius: Number(renderer.prop("radius", Style.cornerRadius))
        border.width: String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0
        border.color: renderer.prop("border_color", "transparent")
      }

      Instantiator {
        model: Array.isArray(nativeMenu.menuData.items) ? nativeMenu.menuData.items : []
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
              text: menuBarRoot.labelOf(modelData)
              enabled: nativeMenu.enabled && menuBarRoot.valueOf(modelData, "enabled", true) !== false
              checkable: menuBarRoot.valueOf(modelData, "checkable", false) === true
              checked: menuBarRoot.valueOf(modelData, "checked", false) === true
              font.family: String(renderer.prop("font_family", renderer.fontFamily))
              font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
              icon.name: String(menuBarRoot.valueOf(modelData, "icon", ""))
              icon.source: String(menuBarRoot.valueOf(modelData, "icon_source", ""))
              icon.color: checked ? renderer.prop("accent", Color.accent)
                : renderer.prop("foreground", renderer.foreground)
              onClicked: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
                "trigger", menuBarRoot.itemPayload(nativeMenu.menuIndex, index, modelData, this))
              onToggled: {
                if (renderer.subscribed("toggle"))
                  renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
                    "toggle", menuBarRoot.itemPayload(nativeMenu.menuIndex, index, modelData, this))
              }
              onHighlightedChanged: {
                if (highlighted && renderer.subscribed("highlight"))
                  renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
                    "highlight", menuBarRoot.itemPayload(nativeMenu.menuIndex, index, modelData, this))
              }
            }
          }
        }
        onObjectAdded: function(index, object) { nativeMenu.insertItem(index, object) }
        onObjectRemoved: function(index, object) { nativeMenu.removeItem(object) }
      }

      onOpened: {
        if (renderer.subscribed("menu_open"))
          renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "menu_open",
            { index: menuIndex, title: title })
      }
      onClosed: {
        if (renderer.subscribed("menu_close"))
          renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "menu_close",
            { index: menuIndex, title: title })
      }
    }
    onObjectAdded: function(index, object) { menuBarRoot.insertMenu(index, object) }
    onObjectRemoved: function(index, object) { menuBarRoot.removeMenu(object) }
  }

  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
  onActiveFocusChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    activeFocus ? "focus" : "blur", {})
}
