import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Layouts
import "../../Theme"

QQC.SwipeDelegate {
  id: swipeRoot

  required property var renderer
  readonly property bool selected: renderer.prop("selected", false) === true
  readonly property bool hasLeftAction: String(renderer.prop("left_action", "")).length > 0
    || String(renderer.prop("left_icon", "")).length > 0
  readonly property bool hasRightAction: String(renderer.prop("right_action", "")).length > 0
    || String(renderer.prop("right_icon", "")).length > 0
  readonly property string requestedSide: String(renderer.prop("opened_side", "none"))

  function eventPayload() {
    return {
      text: text,
      value: renderer.prop("value", text),
      selected: selected
    }
  }

  function actionPayload(side) {
    var isLeft = side === "left"
    return {
      side: side,
      action: String(renderer.prop(isLeft ? "left_action" : "right_action", "")),
      value: renderer.prop(isLeft ? "left_value" : "right_value",
        renderer.prop("value", text)),
      item_value: renderer.prop("value", text)
    }
  }

  function triggerAction(side) {
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
      side === "left" ? "left_action" : "right_action", actionPayload(side))
    if (renderer.prop("close_on_action", true) !== false) swipe.close()
  }

  function syncOpenedSide() {
    if (!swipe.enabled) return
    if (requestedSide === "left" && hasLeftAction) swipe.open(QQC.SwipeDelegate.Left)
    else if (requestedSide === "right" && hasRightAction) swipe.open(QQC.SwipeDelegate.Right)
    else if (requestedSide === "none" || requestedSide === "closed") swipe.close()
  }

  text: String(renderer.prop("text", ""))
  highlighted: renderer.prop("highlighted", selected) === true
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false
  hoverEnabled: true
  implicitWidth: Number(renderer.prop("width", 360))
  implicitHeight: Number(renderer.prop("height", 60))
  padding: Number(renderer.prop("padding", Style.spacing.md))
  font.family: String(renderer.prop("font_family", renderer.fontFamily))
  font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
  Accessible.name: String(renderer.prop("accessible_name", text))

  swipe.enabled: renderer.prop("swipe_enabled", true) !== false
  swipe.left: hasLeftAction ? leftActionComponent : null
  swipe.right: hasRightAction ? rightActionComponent : null
  swipe.transition: Transition {
    NumberAnimation {
      properties: "x"
      duration: renderer.prop("animated", true) !== false
        ? Number(renderer.prop("duration", 180)) : 0
      easing.type: Easing.InOutCubic
    }
  }

  background: Rectangle {
    color: swipeRoot.highlighted
      ? renderer.prop("highlighted_background", renderer.prop("selected_background", Color.popups.background))
      : (swipeRoot.selected
        ? renderer.prop("selected_background", Color.popups.background)
        : renderer.prop("background", Color.background))
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
      fillMode: Image.PreserveAspectFit
      onStatusChanged: {
        if (status === Image.Error)
          renderer.componentError("swipe_delegate_icon_failed",
            "Unable to load the declared swipe delegate icon image", { source: String(source) })
      }
    }

    Text {
      Layout.preferredWidth: Number(renderer.prop("icon_size", 22))
      Layout.alignment: Qt.AlignVCenter
      visible: text.length > 0 && String(renderer.prop("icon_source", "")).length === 0
      text: String(renderer.prop("icon", "")).length > 0
        ? renderer.iconGlyph(renderer.prop("icon", "")) : ""
      color: renderer.prop("icon_color", renderer.prop("foreground", renderer.foreground))
      font.family: renderer.iconFontFamilyFor(renderer.prop("icon", ""))
      font.pixelSize: Number(renderer.prop("icon_size", 22))
      horizontalAlignment: Text.AlignHCenter
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: Style.spacing.xs
      Text {
        Layout.fillWidth: true
        text: swipeRoot.text
        color: swipeRoot.selected
          ? renderer.prop("selected_foreground", renderer.prop("foreground", renderer.foreground))
          : renderer.prop("foreground", renderer.foreground)
        font: swipeRoot.font
        elide: Text.ElideRight
      }
      Text {
        Layout.fillWidth: true
        visible: text.length > 0
        text: String(renderer.prop("description", ""))
        color: renderer.prop("muted", Color.muted)
        font.family: String(renderer.prop("font_family", renderer.fontFamily))
        font.pixelSize: Number(renderer.prop("description_size", Style.font.caption))
        elide: Text.ElideRight
      }
    }
  }

  Component {
    id: leftActionComponent
    Rectangle {
      implicitWidth: Number(renderer.prop("action_width", 96))
      color: renderer.prop("left_color", renderer.prop("accent", Color.accent))
      Row {
        anchors.centerIn: parent
        spacing: Style.spacing.sm
        Text {
          visible: text.length > 0
          text: renderer.iconGlyph(renderer.prop("left_icon", ""))
          color: Color.background
          font.family: renderer.iconFontFamilyFor(renderer.prop("left_icon", ""))
          font.pixelSize: Number(renderer.prop("icon_size", 22))
        }
        Text {
          visible: text.length > 0
          text: String(renderer.prop("left_action", ""))
          color: Color.background
          font.family: String(renderer.prop("font_family", renderer.fontFamily))
          font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
        }
      }
      QQC.SwipeDelegate.onClicked: swipeRoot.triggerAction("left")
    }
  }

  Component {
    id: rightActionComponent
    Rectangle {
      implicitWidth: Number(renderer.prop("action_width", 96))
      color: renderer.prop("right_color", Color.urgent)
      Row {
        anchors.centerIn: parent
        spacing: Style.spacing.sm
        Text {
          visible: text.length > 0
          text: renderer.iconGlyph(renderer.prop("right_icon", ""))
          color: Color.background
          font.family: renderer.iconFontFamilyFor(renderer.prop("right_icon", ""))
          font.pixelSize: Number(renderer.prop("icon_size", 22))
        }
        Text {
          visible: text.length > 0
          text: String(renderer.prop("right_action", ""))
          color: Color.background
          font.family: String(renderer.prop("font_family", renderer.fontFamily))
          font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
        }
      }
      QQC.SwipeDelegate.onClicked: swipeRoot.triggerAction("right")
    }
  }

  Connections {
    target: swipeRoot.swipe
    function onPositionChanged() {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "swipe_position", {
        value: swipeRoot.swipe.position,
        side: swipeRoot.swipe.position > 0 ? "left" : (swipeRoot.swipe.position < 0 ? "right" : "none")
      })
    }
    function onCompleted() {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "swipe_complete", {
        position: swipeRoot.swipe.position,
        side: swipeRoot.swipe.position > 0 ? "left" : "right"
      })
    }
    function onOpened() {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "swipe_open", {
        side: swipeRoot.swipe.position > 0 ? "left" : "right"
      })
    }
    function onClosed() {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "swipe_close", {})
    }
  }

  Component.onCompleted: syncOpenedSide()
  onRequestedSideChanged: syncOpenedSide()
  onClicked: {
    var payload = eventPayload()
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", payload)
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "activate", payload)
  }
  onPressed: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "press", eventPayload())
  onReleased: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "release", eventPayload())
  onHoveredChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    "hover", { value: hovered })
  onActiveFocusChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    activeFocus ? "focus" : "blur", {})
  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
}
