import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"

QQC.ItemDelegate {
  id: delegateRoot

  required property var renderer
  readonly property bool selected: renderer.prop("selected", false) === true

  function eventPayload() {
    return {
      text: text,
      value: renderer ? renderer.prop("value", text) : text,
      checked: checked,
      selected: selected
    }
  }

  // A delegate's signals fire while it is being torn down: replacing a page
  // hides every delegate on the way out, drops the hover and takes the focus
  // away, and the handler then runs against a renderer whose ControlNode has
  // already gone. That is what reported "Cannot read property 'bridge' of
  // undefined" from here, over and over, on every page switch.
  //
  // Asking the renderer what it is subscribed to before building a payload
  // also stops the client posting show, hide, hover, focus and blur traffic
  // for delegates nobody is listening to, which on a page of several hundred
  // nodes is nearly all of them.
  function postEvent(eventName, payload) {
    if (!renderer || !renderer.bridge || !renderer.subscribed(eventName)) return
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, eventName, payload)
  }

  text: String(renderer.prop("text", ""))
  checkable: renderer.prop("checkable", false) === true
  checked: renderer.prop("checked", false) === true
  autoExclusive: renderer.prop("auto_exclusive", false) === true
  highlighted: renderer.prop("highlighted", selected) === true
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false
  hoverEnabled: true
  implicitWidth: Number(renderer.prop("width", 320))
  implicitHeight: Number(renderer.prop("height", 56))
  padding: Number(renderer.prop("padding", Style.spacing.md))
  font.family: String(renderer.prop("font_family", renderer.fontFamily))
  font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
  Accessible.name: String(renderer.prop("accessible_name", text))
  Accessible.role: Accessible.ListItem

  background: Rectangle {
    readonly property color restingColor: delegateRoot.highlighted
      ? renderer.prop("highlighted_background", renderer.prop("selected_background", Color.popups.background))
      : (delegateRoot.selected
        ? renderer.prop("selected_background", Color.popups.background)
        : renderer.prop("background", "transparent"))
    color: delegateRoot.down ? renderer.pressedBackground(restingColor) : restingColor
    radius: Number(renderer.prop("radius", Style.cornerRadius))
    border.width: Number(renderer.prop("border_width",
      String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0))
    border.color: renderer.prop("border_color", "transparent")
  }

  contentItem: RowLayout {
    spacing: Number(renderer.prop("spacing", Style.spacing.md))

    Image {
      Layout.preferredWidth: Number(renderer.prop("icon_size", 22))
      Layout.preferredHeight: Number(renderer.prop("icon_size", 22))
      Layout.alignment: Qt.AlignVCenter
      visible: source.toString().length > 0
      source: String(renderer.prop("icon_source", ""))
      sourceSize.width: width
      sourceSize.height: height
      fillMode: Image.PreserveAspectFit
      onStatusChanged: {
        if (status === Image.Error)
          renderer.componentError("item_delegate_icon_failed",
            "Unable to load the declared item delegate icon image", { source: String(source) })
      }
    }

    Text {
      Layout.preferredWidth: Number(renderer.prop("icon_size", 22))
      Layout.alignment: Qt.AlignVCenter
      visible: text.length > 0 && String(renderer.prop("icon_source", "")).length === 0
      text: String(renderer.prop("icon", "")).length > 0
        ? renderer.iconGlyph(renderer.prop("icon", "")) : ""
      textFormat: Text.PlainText
      color: renderer.prop("icon_color", delegateRoot.selected
        ? renderer.prop("selected_foreground", renderer.prop("accent", Color.accent))
        : renderer.prop("foreground", renderer.foreground))
      font.family: renderer.iconFontFamilyFor(renderer.prop("icon", ""))
      font.pixelSize: Number(renderer.prop("icon_size", 22))
      horizontalAlignment: Text.AlignHCenter
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.spacing.xs

      Text {
        Layout.fillWidth: true
        readonly property color restingColor: delegateRoot.selected
          ? renderer.prop("selected_foreground", renderer.prop("foreground", renderer.foreground))
          : renderer.prop("foreground", renderer.foreground)
        text: delegateRoot.text
        textFormat: Text.PlainText
        color: delegateRoot.down ? renderer.pressedForeground(restingColor) : restingColor
        font: delegateRoot.font
        elide: Text.ElideRight
      }

      Text {
        Layout.fillWidth: true
        visible: text.length > 0
        text: String(renderer.prop("description", ""))
        textFormat: Text.PlainText
        color: renderer.prop("muted", Color.muted)
        font.family: String(renderer.prop("font_family", renderer.fontFamily))
        font.pixelSize: Number(renderer.prop("description_size", Style.font.caption))
        elide: Text.ElideRight
      }
    }

    Text {
      Layout.alignment: Qt.AlignVCenter
      visible: text.length > 0
      text: String(renderer.prop("trailing_text", ""))
      textFormat: Text.PlainText
      color: renderer.prop("muted", Color.muted)
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("description_size", Style.font.caption))
    }

    Text {
      Layout.alignment: Qt.AlignVCenter
      visible: renderer.prop("show_indicator", false) === true
        && String(renderer.prop("trailing_text", "")).length === 0
      text: renderer.iconGlyph("chevron_right")
      textFormat: Text.PlainText
      color: renderer.prop("muted", Color.muted)
      font.family: renderer.iconFontFamily
      font.pixelSize: Number(renderer.prop("icon_size", 22))
    }
  }

  onClicked: {
    var payload = eventPayload()
    postEvent("click", payload)
    postEvent("activate", payload)
  }
  onToggled: {
    var payload = eventPayload()
    postEvent("toggle", payload)
    postEvent("change", payload)
  }
  onPressed: postEvent("press", eventPayload())
  onReleased: postEvent("release", eventPayload())
  onHoveredChanged: postEvent("hover", { value: hovered })
  onActiveFocusChanged: postEvent(activeFocus ? "focus" : "blur", {})
  onVisibleChanged: postEvent(visible ? "show" : "hide", {})
}
