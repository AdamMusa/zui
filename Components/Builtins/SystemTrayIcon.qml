import QtQuick
import Qt.labs.platform as Platform

// Qt.labs.platform's SystemTrayIcon needs a native tray from the platform plugin. The
// cocoa and windows plugins provide one under a plain QGuiApplication, which is what the
// zui host uses; a plugin without one (offscreen, and some Linux setups) makes Qt fall
// back to Qt Widgets, which the host does not link, leaving available false. That case is
// reported through the error channel rather than leaving a tray that silently never shows.
Item {
  id: root
  required property var renderer
  property int handledCommandRevision: -1
  visible: false

  readonly property var activationReasons: ["unknown", "context", "double_click", "trigger", "middle_click"]
  readonly property var messageIcons: ({ none: Platform.SystemTrayIcon.NoIcon,
    information: Platform.SystemTrayIcon.Information, warning: Platform.SystemTrayIcon.Warning,
    critical: Platform.SystemTrayIcon.Critical })

  function send(name, payload) {
    if (renderer.subscribed(name)) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, name, payload || {})
  }
  function menuItems() {
    var values = renderer.prop("menu_items", []) || []
    return Array.isArray(values) ? values : []
  }
  function publishState() {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "state", {
      available: nativeTray.available === true,
      supports_messages: nativeTray.supportsMessages === true,
      visible: nativeTray.visible === true,
      geometry: { x: Number(nativeTray.geometry.x), y: Number(nativeTray.geometry.y),
        width: Number(nativeTray.geometry.width), height: Number(nativeTray.geometry.height) }
    })
  }
  function showMessage() {
    if (!nativeTray.supportsMessages) {
      renderer.componentError("tray_messages_unsupported", "This platform's system tray cannot show messages", {})
      return
    }
    var iconName = String(renderer.prop("message_icon", "information"))
    var icon = messageIcons[iconName]
    if (icon === undefined) {
      renderer.componentError("tray_message_icon_unknown", "The tray message icon is not a Qt message icon",
        { icon: iconName })
      return
    }
    nativeTray.showMessage(String(renderer.prop("message_title", "")),
      String(renderer.prop("message_text", "")), icon, Number(renderer.prop("message_timeout", 10000)))
  }
  function runCommand() {
    var revision = Number(renderer.prop("command_revision", 0))
    if (revision === handledCommandRevision) return
    handledCommandRevision = revision
    var command = String(renderer.prop("command", ""))
    if (command === "") return
    if (!nativeTray.available) {
      renderer.componentError("tray_unavailable", "This platform has no system tray", { command: command })
      return
    }
    if (command === "show") { nativeTray.show(); return }
    if (command === "hide") { nativeTray.hide(); return }
    if (command === "message") { showMessage(); return }
    renderer.componentError("tray_command_rejected", "The system tray does not support the requested command",
      { command: command })
  }

  Platform.SystemTrayIcon {
    id: nativeTray
    visible: root.renderer.prop("visible", true) !== false
    tooltip: String(root.renderer.prop("tooltip", ""))
    icon.source: root.renderer.assetUrl(root.renderer.prop("icon_source", ""))
    icon.name: String(root.renderer.prop("icon_name", ""))
    menu: trayMenu
    onActivated: function(reason) {
      root.send("activated", { reason: Number(reason),
        reason_name: root.activationReasons[Number(reason)] || "unknown" })
    }
    onMessageClicked: root.send("message_click", {})
    onVisibleChanged: root.publishState()
  }

  // SystemTrayIcon.menu takes a Qt.labs.platform Menu, not a QtQuick.Controls one, so the
  // tray menu is built from native MenuItems here. MenuItemGroup is what makes a set of
  // them mutually exclusive, which is the only place that type has anything to group.
  Platform.MenuItemGroup {
    id: exclusiveGroup
    exclusive: true
    onTriggered: function(item) {
      root.send("menu_trigger", { text: String(item.text), checked: item.checked === true, exclusive: true })
    }
  }
  Platform.Menu {
    id: trayMenu
    Instantiator {
      model: root.menuItems()
      onObjectAdded: function(index, object) { trayMenu.insertItem(index, object) }
      onObjectRemoved: function(index, object) { trayMenu.removeItem(object) }
      delegate: Platform.MenuItem {
        required property var modelData
        text: String(modelData.text || "")
        enabled: modelData.enabled !== false
        separator: modelData.separator === true
        checkable: modelData.checkable === true
        checked: modelData.checked === true
        group: modelData.exclusive === true ? exclusiveGroup : null
        onTriggered: root.send("menu_trigger",
          { text: text, checked: checked, exclusive: modelData.exclusive === true })
      }
    }
  }

  Connections { target: renderer; function onNodeChanged() { root.runCommand() } }
  Component.onCompleted: {
    if (!nativeTray.available)
      renderer.componentError("tray_unavailable", "This platform has no system tray", {})
    publishState()
    runCommand()
  }
}
