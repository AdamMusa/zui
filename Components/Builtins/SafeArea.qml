import QtQuick

Item {
  id: root
  required property var renderer
  readonly property var configuredEdges: { var value=renderer.prop("edges", ["left","top","right","bottom"]);return Array.isArray(value)?value:[value] }
  readonly property real extraPadding: Number(renderer.prop("padding", 0))
  readonly property real safeLeft: configuredEdges.indexOf("left") >= 0 ? Number(zuiSafeArea.left) : 0
  readonly property real safeTop: configuredEdges.indexOf("top") >= 0 ? Number(zuiSafeArea.top) : 0
  readonly property real safeRight: configuredEdges.indexOf("right") >= 0 ? Number(zuiSafeArea.right) : 0
  readonly property real safeBottom: configuredEdges.indexOf("bottom") >= 0 ? Number(zuiSafeArea.bottom) : 0
  implicitWidth: Number(renderer.prop("width", contentHost.childrenRect.width + safeLeft + safeRight + extraPadding * 2))
  implicitHeight: Number(renderer.prop("height", contentHost.childrenRect.height + safeTop + safeBottom + extraPadding * 2))
  visible: renderer.prop("visible", true) !== false
  Rectangle { anchors.fill: parent; color: renderer.prop("background", "transparent") }
  Item {
    id: contentHost
    anchors.fill: parent
    anchors.leftMargin: root.safeLeft + root.extraPadding
    anchors.topMargin: root.safeTop + root.extraPadding
    anchors.rightMargin: root.safeRight + root.extraPadding
    anchors.bottomMargin: root.safeBottom + root.extraPadding
    Repeater { model: renderer.node.children || []; delegate: renderer.childDelegateComponent }
  }
  TapHandler { onTapped: renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "click", {}) }
  function publish() { renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"change",{left:safeLeft,top:safeTop,right:safeRight,bottom:safeBottom}) }
  Connections { target: zuiSafeArea; function onChanged() { root.publish() } }
  Component.onCompleted: publish()
}
