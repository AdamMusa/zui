import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.Page {
  id: pageRoot

  required property var renderer
  readonly property string contentLayout: String(renderer.prop("layout", "column"))

  title: String(renderer.prop("title", ""))
  implicitWidth: Number(renderer.prop("width", 640))
  implicitHeight: Number(renderer.prop("height", 480))
  enabled: renderer.prop("enabled", true) !== false
  padding: Number(renderer.prop("padding", Style.spacing.lg))
  leftPadding: padding
  rightPadding: padding
  topPadding: padding
  bottomPadding: padding
  font.family: String(renderer.prop("font_family", renderer.fontFamily))
  font.pixelSize: Number(renderer.prop("font_size", Style.font.body))

  background: Rectangle {
    color: renderer.prop("background", Color.background)
    radius: Number(renderer.prop("radius", 0))
    border.width: String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0
    border.color: renderer.prop("border_color", "transparent")
  }

  header: Rectangle {
    visible: renderer.prop("show_header", true) !== false
      && String(renderer.prop("header_text", pageRoot.title)).length > 0
    implicitHeight: visible ? Number(renderer.prop("header_height", 56)) : 0
    color: renderer.prop("header_background", renderer.prop("background", Color.background))
    Text {
      anchors.fill: parent
      anchors.leftMargin: pageRoot.padding
      anchors.rightMargin: pageRoot.padding
      text: String(renderer.prop("header_text", pageRoot.title))
      color: renderer.prop("foreground", renderer.foreground)
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("title_size", Style.font.heading))
      font.bold: true
      verticalAlignment: Text.AlignVCenter
      elide: Text.ElideRight
    }
  }

  footer: Rectangle {
    visible: renderer.prop("show_footer", true) !== false
      && String(renderer.prop("footer_text", "")).length > 0
    implicitHeight: visible ? Number(renderer.prop("footer_height", 40)) : 0
    color: renderer.prop("footer_background", renderer.prop("background", Color.background))
    Text {
      anchors.fill: parent
      anchors.leftMargin: pageRoot.padding
      anchors.rightMargin: pageRoot.padding
      text: String(renderer.prop("footer_text", ""))
      color: renderer.prop("muted", Color.muted)
      font.family: String(renderer.prop("font_family", renderer.fontFamily))
      font.pixelSize: Number(renderer.prop("footer_size", Style.font.caption))
      verticalAlignment: Text.AlignVCenter
      elide: Text.ElideRight
    }
  }

  contentItem: Item {
    LayoutMirroring.enabled: String(renderer.prop("layout_direction", "left_to_right")) === "right_to_left"
    LayoutMirroring.childrenInherit: true

    Loader {
      anchors.fill: parent
      sourceComponent: pageRoot.contentLayout === "row" ? rowContent
        : (pageRoot.contentLayout === "stack" ? stackContent : columnContent)
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
  onTitleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    "title_change", { value: title })
}
