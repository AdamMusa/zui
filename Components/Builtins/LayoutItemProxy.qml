import QtQuick
import QtQuick.Layouts

LayoutItemProxy {
  id: proxy

  required property var renderer
  readonly property string targetId: String(renderer.prop("target", ""))

  Layout.fillWidth: renderer.prop("fill_width", false) === true
  Layout.fillHeight: renderer.prop("fill_height", false) === true
  Layout.preferredWidth: Number(renderer.prop("preferred_width", -1))
  Layout.preferredHeight: Number(renderer.prop("preferred_height", -1))
  Layout.minimumWidth: Number(renderer.prop("minimum_width", 0))
  Layout.minimumHeight: Number(renderer.prop("minimum_height", 0))
  Layout.maximumWidth: Number(renderer.prop("maximum_width", Infinity))
  Layout.maximumHeight: Number(renderer.prop("maximum_height", Infinity))
  Layout.alignment: renderer.layoutAlignment(renderer.prop("alignment", "center"), "center")
  Layout.margins: Number(renderer.prop("margins", 0))
  Layout.leftMargin: Number(renderer.prop("left_margin", Layout.margins))
  Layout.topMargin: Number(renderer.prop("top_margin", Layout.margins))
  Layout.rightMargin: Number(renderer.prop("right_margin", Layout.margins))
  Layout.bottomMargin: Number(renderer.prop("bottom_margin", Layout.margins))

  function resolveTarget() {
    var resolved = renderer.findRenderedItem(targetId)
    if (resolved && resolved !== proxy) target = resolved
  }

  function synchronizeDimensions() {
    var resolvedWidth = renderer.hasProp("width") ? Number(renderer.prop("width", 0)) : implicitWidth
    var resolvedHeight = renderer.hasProp("height") ? Number(renderer.prop("height", 0)) : implicitHeight
    if (!isNaN(resolvedWidth) && width !== resolvedWidth) width = resolvedWidth
    if (!isNaN(resolvedHeight) && height !== resolvedHeight) height = resolvedHeight
  }

  onTargetIdChanged: {
    target = null
    Qt.callLater(resolveTarget)
  }
  onTargetChanged: {
    Qt.callLater(synchronizeDimensions)
    if (renderer.subscribed("target_change"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "target_change", {
        target: target ? targetId : null,
        resolved: target !== null
      })
  }
  Component.onCompleted: {
    Qt.callLater(resolveTarget)
    Qt.callLater(synchronizeDimensions)
  }

  Connections {
    target: proxy.renderer
    function onNodeChanged() { Qt.callLater(proxy.synchronizeDimensions) }
  }

  Timer {
    interval: 16
    repeat: true
    running: proxy.targetId !== "" && proxy.target === null
    onTriggered: proxy.resolveTarget()
  }
}
