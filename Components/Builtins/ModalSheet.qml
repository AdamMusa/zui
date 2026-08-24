import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.Popup {
  id: modalSheetRoot

  required property var renderer
  readonly property bool requestedOpen: renderer.prop("opened", false) === true
    && renderer.prop("visible", true) !== false
  readonly property string sheetEdge: String(renderer.prop("edge", "right"))
  readonly property string contentLayout: String(renderer.prop("layout", "column"))
  readonly property real sheetMargin: Number(renderer.prop("margin", Style.spacing.md))
  readonly property real maximumWidth: Number(renderer.prop("max_width", 720))
  readonly property real maximumHeight: Number(renderer.prop("max_height", 900))
  readonly property bool horizontalEdge: sheetEdge === "top" || sheetEdge === "bottom"
  property bool dismissalReported: false

  function closePolicyValue(value) {
    if (renderer.prop("dismissible", true) === false) return QQC.Popup.NoAutoClose
    var names = Array.isArray(value) ? value : [value || "escape_and_outside"]
    var result = 0
    for (var index = 0; index < names.length; index++) {
      var name = String(names[index])
      if (name === "none") continue
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

  function reportDismiss(reason) {
    if (dismissalReported) return
    dismissalReported = true
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "dismiss", { reason: reason })
  }

  function dismiss(reason) {
    if (renderer.prop("dismissible", true) === false) return
    reportDismiss(reason)
    close()
  }

  function hiddenX() {
    if (!parent) return x
    if (sheetEdge === "left") return -width
    if (sheetEdge === "right") return parent.width
    return x
  }

  function hiddenY() {
    if (!parent) return y
    if (sheetEdge === "top") return -height
    if (sheetEdge === "bottom") return parent.height
    return y
  }

  x: {
    if (!parent) return sheetMargin
    if (sheetEdge === "left") return sheetMargin
    if (sheetEdge === "right") return parent.width - width - sheetMargin
    return Math.max(sheetMargin, (parent.width - width) / 2)
  }
  y: {
    if (!parent) return sheetMargin
    if (sheetEdge === "top") return sheetMargin
    if (sheetEdge === "bottom") return parent.height - height - sheetMargin
    return Math.max(sheetMargin, (parent.height - height) / 2)
  }
  width: {
    var available = parent ? Math.max(0, parent.width - sheetMargin * 2) : maximumWidth
    var defaultWidth = horizontalEdge ? available : Math.min(520, available)
    return Math.min(Number(renderer.prop("width", defaultWidth)), available, maximumWidth)
  }
  height: {
    var available = parent ? Math.max(0, parent.height - sheetMargin * 2) : maximumHeight
    var defaultHeight = horizontalEdge ? Math.min(420, available) : available
    return Math.min(Number(renderer.prop("height", defaultHeight)), available, maximumHeight)
  }
  modal: renderer.prop("modal", true) !== false
  dim: renderer.prop("dim", modal) !== false
  focus: true
  closePolicy: closePolicyValue(renderer.prop("close_policy", "escape_and_outside"))
  enabled: renderer.prop("enabled", true) !== false
  padding: Number(renderer.prop("padding", Style.spacing.lg))

  background: Rectangle {
    color: renderer.prop("background", Color.background)
    radius: Number(renderer.prop("radius", Style.cornerRadius))
    border.width: String(renderer.prop("border_color", "")).length > 0 ? Style.normalBorderWidth : 0
    border.color: renderer.prop("border_color", "transparent")
  }

  contentItem: Column {
    spacing: Number(renderer.prop("spacing", Style.spacing.md))

    Rectangle {
      width: parent.width
      height: renderer.prop("show_header", true) !== false
        ? Number(renderer.prop("header_height", 48)) : 0
      visible: height > 0
      color: renderer.prop("header_background", "transparent")

      Text {
        anchors.left: parent.left
        anchors.right: closeButton.visible ? closeButton.left : parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: Style.spacing.sm
        text: String(renderer.prop("title", ""))
        color: renderer.prop("foreground", renderer.foreground)
        font.family: String(renderer.prop("font_family", renderer.fontFamily))
        font.pixelSize: Number(renderer.prop("title_size", Style.font.heading))
        font.bold: true
        elide: Text.ElideRight
      }

      QQC.ToolButton {
        id: closeButton
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        visible: renderer.prop("show_close", true) !== false
          && renderer.prop("dismissible", true) !== false
        text: renderer.iconGlyph("xmark")
        font.family: renderer.iconFontFamily
        font.pixelSize: Number(renderer.prop("font_size", Style.font.body))
        onClicked: modalSheetRoot.dismiss("close_button")
      }
    }

    Loader {
      width: parent.width
      height: Math.max(0, parent.height - y)
      sourceComponent: modalSheetRoot.contentLayout === "row" ? rowContent
        : (modalSheetRoot.contentLayout === "stack" ? stackContent : columnContent)
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

  enter: Transition {
    ParallelAnimation {
      NumberAnimation {
        property: "opacity"; from: 0; to: 1
        duration: renderer.prop("animated", true) !== false
          ? Number(renderer.prop("duration", 220)) : 0
        easing.type: renderer.easingType(renderer.prop("easing", "out_cubic"))
      }
      NumberAnimation {
        property: modalSheetRoot.horizontalEdge ? "y" : "x"
        from: modalSheetRoot.horizontalEdge ? modalSheetRoot.hiddenY() : modalSheetRoot.hiddenX()
        duration: renderer.prop("animated", true) !== false
          ? Number(renderer.prop("duration", 220)) : 0
        easing.type: renderer.easingType(renderer.prop("easing", "out_cubic"))
      }
    }
  }

  exit: Transition {
    ParallelAnimation {
      NumberAnimation {
        property: "opacity"; from: 1; to: 0
        duration: renderer.prop("animated", true) !== false
          ? Number(renderer.prop("duration", 180)) : 0
        easing.type: renderer.easingType("in_cubic")
      }
      NumberAnimation {
        property: modalSheetRoot.horizontalEdge ? "y" : "x"
        to: modalSheetRoot.horizontalEdge ? modalSheetRoot.hiddenY() : modalSheetRoot.hiddenX()
        duration: renderer.prop("animated", true) !== false
          ? Number(renderer.prop("duration", 180)) : 0
        easing.type: renderer.easingType("in_cubic")
      }
    }
  }

  Component.onCompleted: syncOpenState()
  onRequestedOpenChanged: syncOpenState()
  onOpened: {
    dismissalReported = false
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "open", {})
  }
  onClosed: {
    if (requestedOpen && !dismissalReported) reportDismiss("close_policy")
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "close", {})
  }
  onAboutToShow: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "about_to_show", {})
  onAboutToHide: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "about_to_hide", {})
  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
  onActiveFocusChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    activeFocus ? "focus" : "blur", {})
}
