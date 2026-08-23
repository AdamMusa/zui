import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.GroupBox {
  id: groupRoot

  required property var renderer
  readonly property string contentLayout: String(renderer.prop("layout", "column"))

  title: String(renderer.prop("title", ""))
  implicitWidth: Number(renderer.prop("width", 420))
  implicitHeight: Number(renderer.prop("height", 260))
  enabled: renderer.prop("enabled", true) !== false
  visible: renderer.prop("visible", true) !== false
  clip: renderer.prop("clip", false) === true
  padding: Number(renderer.prop("padding", Style.spacing.lg))
  leftPadding: Number(renderer.prop("left_padding", padding))
  rightPadding: Number(renderer.prop("right_padding", padding))
  topPadding: Number(renderer.prop("top_padding", padding + titleLabel.implicitHeight + Style.spacing.sm))
  bottomPadding: Number(renderer.prop("bottom_padding", padding))

  label: Text {
    id: titleLabel
    x: groupRoot.leftPadding
    width: Math.max(0, groupRoot.width - groupRoot.leftPadding - groupRoot.rightPadding)
    text: groupRoot.title
    color: renderer.prop("foreground", renderer.foreground)
    font.family: String(renderer.prop("font_family", renderer.fontFamily))
    font.pixelSize: Number(renderer.prop("title_size",
      renderer.prop("font_size", Style.font.body)))
    font.bold: true
    horizontalAlignment: {
      var alignment = String(renderer.prop("title_alignment", "left"))
      if (alignment === "center") return Text.AlignHCenter
      if (alignment === "right" || alignment === "end") return Text.AlignRight
      return Text.AlignLeft
    }
    elide: Text.ElideRight
  }

  background: Rectangle {
    y: titleLabel.implicitHeight / 2
    height: groupRoot.height - y
    color: renderer.prop("background", "transparent")
    radius: Number(renderer.prop("radius", Style.cornerRadius))
    border.width: Number(renderer.prop("border_width", Style.normalBorderWidth))
    border.color: renderer.prop("border_color", Color.border)
  }

  contentItem: Item {
    LayoutMirroring.enabled: String(renderer.prop("layout_direction", "left_to_right")) === "right_to_left"
    LayoutMirroring.childrenInherit: true

    Loader {
      anchors.fill: parent
      sourceComponent: groupRoot.contentLayout === "row" ? rowContent
        : (groupRoot.contentLayout === "stack" ? stackContent : columnContent)
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
