import QtQuick
import QtQuick.Controls as QQC
import "../../Theme"

QQC.Popup {
  id: sheetRoot

  required property var renderer
  readonly property bool requestedOpen: renderer.prop("opened", false) === true
    && renderer.prop("visible", true) !== false
  readonly property string contentLayout: String(renderer.prop("layout", "column"))
  readonly property real sheetMargin: Number(renderer.prop("margin", Style.spacing.md))
  readonly property real maximumWidth: Number(renderer.prop("max_width", 720))
  readonly property real restingX: parent ? Math.max(sheetMargin,
    (parent.width - width) / 2) : sheetMargin
  readonly property real restingY: parent ? Math.max(0, parent.height - height - sheetMargin) : 0
  property real dragOffset: 0
  property real dragStartOffset: 0

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

  function updateDrag(value) {
    dragOffset = Math.max(0, Math.min(height, value))
    if (renderer.subscribed("drag"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "drag", {
        offset: dragOffset, progress: height > 0 ? dragOffset / height : 0
      })
  }

  function finishDrag() {
    var progress = height > 0 ? dragOffset / height : 0
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "drag_end", {
      offset: dragOffset, progress: progress
    })
    if (renderer.prop("dismissible", true) !== false
        && progress >= Number(renderer.prop("dismiss_threshold", 0.3))) {
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "dismiss", {
        offset: dragOffset, progress: progress
      })
      close()
    } else {
      dragReturn.restart()
    }
  }

  x: restingX
  y: restingY + dragOffset
  width: {
    var available = parent ? parent.width - sheetMargin * 2 : maximumWidth
    var requested = Number(renderer.prop("width", Math.min(available, maximumWidth)))
    return Math.max(0, Math.min(requested, available, maximumWidth))
  }
  height: Number(renderer.prop("height", 320))
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

    Item {
      width: parent.width
      height: renderer.prop("handle_visible", true) !== false
        ? Math.max(Number(renderer.prop("handle_height", 4)) + Style.spacing.sm * 2, 24) : 0
      visible: height > 0

      Rectangle {
        anchors.centerIn: parent
        width: Number(renderer.prop("handle_width", 44))
        height: Number(renderer.prop("handle_height", 4))
        radius: height / 2
        color: renderer.prop("muted", Color.muted)
      }

      DragHandler {
        id: sheetDragHandler
        enabled: renderer.prop("draggable", true) !== false
          && renderer.prop("dismissible", true) !== false
        target: null
        xAxis.enabled: false
        onActiveChanged: {
          if (active) sheetRoot.dragStartOffset = sheetRoot.dragOffset
          else sheetRoot.finishDrag()
        }
        onTranslationChanged: {
          if (active) sheetRoot.updateDrag(sheetRoot.dragStartOffset + translation.y)
        }
      }
    }

    Loader {
      width: parent.width
      height: Math.max(0, parent.height - y)
      sourceComponent: sheetRoot.contentLayout === "row" ? rowContent
        : (sheetRoot.contentLayout === "stack" ? stackContent : columnContent)
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

  NumberAnimation {
    id: dragReturn
    target: sheetRoot
    property: "dragOffset"
    to: 0
    duration: renderer.prop("animated", true) !== false
      ? Number(renderer.prop("duration", 180)) : 0
    easing.type: renderer.easingType(renderer.prop("easing", "out_cubic"))
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
        property: "y"; from: sheetRoot.parent ? sheetRoot.parent.height : sheetRoot.restingY
        to: sheetRoot.restingY
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
        property: "y"; from: sheetRoot.y
        to: sheetRoot.parent ? sheetRoot.parent.height : sheetRoot.y + sheetRoot.height
        duration: renderer.prop("animated", true) !== false
          ? Number(renderer.prop("duration", 180)) : 0
        easing.type: renderer.easingType("in_cubic")
      }
    }
  }

  Component.onCompleted: syncOpenState()
  onRequestedOpenChanged: syncOpenState()
  onOpened: {
    dragOffset = 0
    renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "open", {})
  }
  onClosed: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "close", {})
  onAboutToShow: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "about_to_show", {})
  onAboutToHide: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "about_to_hide", {})
  onVisibleChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    visible ? "show" : "hide", {})
  onActiveFocusChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId,
    activeFocus ? "focus" : "blur", {})
}
