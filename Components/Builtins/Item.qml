import QtQuick

Item {
  id: itemRoot
  required property var renderer
  implicitWidth: Number(renderer.prop("width", itemContent.implicitWidth))
  implicitHeight: Number(renderer.prop("height", itemContent.implicitHeight))
  clip: renderer.prop("clip", false) === true
  antialiasing: renderer.prop("antialiasing", false) === true
  smooth: renderer.prop("smooth", true) !== false
  baselineOffset: Number(renderer.prop("baseline_offset", 0))
  focus: renderer.prop("focus", false) === true
  transformOrigin: itemRoot.origin()

  function origin() {
    var requested = String(renderer.prop("transform_origin", "center"))
    if (requested === "top_left") return Item.TopLeft
    if (requested === "top") return Item.Top
    if (requested === "top_right") return Item.TopRight
    if (requested === "left") return Item.Left
    if (requested === "right") return Item.Right
    if (requested === "bottom_left") return Item.BottomLeft
    if (requested === "bottom") return Item.Bottom
    if (requested === "bottom_right") return Item.BottomRight
    return Item.Center
  }

  function requestFocus() {
    if (renderer.prop("active_focus", false) === true) forceActiveFocus()
  }

  Item {
    id: itemContent
    anchors.fill: parent
    implicitWidth: childrenRect.width
    implicitHeight: childrenRect.height
    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  }

  onWidthChanged: if (renderer.subscribed("size_change")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "size_change", { width: width, height: height })
  onHeightChanged: if (renderer.subscribed("size_change")) renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "size_change", { width: width, height: height })
  onActiveFocusChanged: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, activeFocus ? "focus" : "blur", { value: activeFocus })

  Component.onCompleted: requestFocus()
  Connections { target: renderer; function onNodeChanged() { itemRoot.requestFocus() } }
}
