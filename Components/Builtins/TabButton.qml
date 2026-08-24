import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.TabButton {
  id: buttonRoot

  required property var renderer

  text: String(renderer.prop("text", ""))
  checked: renderer.prop("checked", false) === true
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false
  autoExclusive: renderer.prop("auto_exclusive", true) !== false
  hoverEnabled: renderer.subscribed("hover")
  implicitWidth: Number(renderer.prop("width", 140))
  implicitHeight: Number(renderer.prop("height", 44))
  icon.name: String(renderer.prop("icon", ""))
  icon.source: String(renderer.prop("icon_source", ""))
  icon.color: renderer.prop("icon_color", renderer.prop("foreground", renderer.foreground))
  icon.width: Number(renderer.prop("icon_width", Style.font.body))
  icon.height: Number(renderer.prop("icon_height", Style.font.body))
  font.family: String(renderer.prop("font_family", renderer.fontFamily))
  font.pixelSize: Number(renderer.prop("font_size", Style.font.body))

  contentItem: Row {
    spacing: Style.spacing.sm
    anchors.centerIn: parent

    Image {
      visible: source.toString().length > 0
      source: String(renderer.prop("icon_source", ""))
      width: Number(renderer.prop("icon_width", Style.font.body))
      height: Number(renderer.prop("icon_height", Style.font.body))
      fillMode: Image.PreserveAspectFit
      onStatusChanged: {
        if (status === Image.Error)
          renderer.componentError("tab_button_icon_failed",
            "Unable to load the declared tab button icon image", { source: String(source) })
      }
    }

    Text {
      visible: String(renderer.prop("icon", "")).length > 0
        && String(renderer.prop("icon_source", "")).length === 0
      text: renderer.iconGlyph(renderer.prop("icon", ""))
      color: renderer.prop("icon_color", renderer.prop("foreground", renderer.foreground))
      font.family: renderer.iconFontFamilyFor(renderer.prop("icon", ""))
      font.pixelSize: Number(renderer.prop("icon_width", Style.font.body))
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      text: buttonRoot.text
      color: !buttonRoot.enabled ? renderer.prop("muted", Color.muted)
        : (buttonRoot.checked ? renderer.prop("checked_foreground", renderer.prop("accent", Color.accent))
          : renderer.prop("foreground", renderer.foreground))
      font: buttonRoot.font
      anchors.verticalCenter: parent.verticalCenter
      elide: Text.ElideRight
    }
  }

  background: Rectangle {
    color: buttonRoot.checked
      ? renderer.prop("checked_background", renderer.prop("background", "transparent"))
      : renderer.prop("background", "transparent")
    radius: Number(renderer.prop("radius", 0))
    border.width: Number(renderer.prop("border_width",
      String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0))
    border.color: renderer.prop("border_color", "transparent")
    Rectangle {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: buttonRoot.checked ? 2 : 0
      color: renderer.prop("accent", Color.accent)
    }
  }

  Shortcut {
    sequence: String(renderer.prop("shortcut", ""))
    enabled: buttonRoot.enabled && sequence.toString().length > 0
    onActivated: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click",
      { checked: buttonRoot.checked, text: buttonRoot.text, shortcut: true })
  }

  onClicked: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click",
    { checked: checked, text: text })
  onToggled: {
    var payload = { value: checked, checked: checked, text: text }
    if (renderer.subscribed("toggle"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "toggle", payload)
    if (renderer.subscribed("change"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "change", payload)
  }
  onPressed: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "press", {})
  onReleased: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "release", {})
  onHoveredChanged: {
    if (renderer.subscribed("hover"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "hover", { value: hovered })
  }
  onActiveFocusChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    activeFocus ? "focus" : "blur", {})
}
