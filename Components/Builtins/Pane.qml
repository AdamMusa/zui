import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.Pane {
  id: paneRoot

  required property var renderer
  readonly property string contentLayout: String(renderer.prop("layout", "column"))

  implicitWidth: Number(renderer.prop("width", 420))
  implicitHeight: Number(renderer.prop("height", 240))
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false
  clip: renderer.prop("clip", false) === true
  padding: Number(renderer.prop("padding", Style.spacing.lg))
  leftPadding: Number(renderer.prop("left_padding", padding))
  rightPadding: Number(renderer.prop("right_padding", padding))
  topPadding: Number(renderer.prop("top_padding", padding))
  bottomPadding: Number(renderer.prop("bottom_padding", padding))

  background: Rectangle {
    color: renderer.prop("background", Color.background)
    radius: Number(renderer.prop("radius", Style.cornerRadius))
    border.width: Number(renderer.prop("border_width",
      String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0))
    border.color: renderer.prop("border_color", "transparent")
  }

  contentItem: Item {
    LayoutMirroring.enabled: String(renderer.prop("layout_direction", "left_to_right")) === "right_to_left"
    LayoutMirroring.childrenInherit: true

    Loader {
      anchors.fill: parent
      sourceComponent: paneRoot.contentLayout === "row" ? rowContent
        : (paneRoot.contentLayout === "stack" ? stackContent : columnContent)
    }
  }

  Component {
    id: columnContent
    Column {
      spacing: Number(renderer.prop("spacing", Style.spacing.md))
      Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
    }
  }

  Component {
    id: rowContent
    Row {
      spacing: Number(renderer.prop("spacing", Style.spacing.md))
      Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
    }
  }

  Component {
    id: stackContent
    Item {
      Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
    }
  }

  TapHandler {
    enabled: renderer.subscribed("click")
    onTapped: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", {})
  }
  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
  onActiveFocusChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    activeFocus ? "focus" : "blur", {})
}
