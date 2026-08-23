import QtQuick
import QtQuick.Layouts

LayoutItemProxy {
  id: proxy

  required property var renderer
  readonly property string targetId: String(renderer.prop("target", ""))

  width: renderer.prop("width", null) === null ? implicitWidth : Number(renderer.prop("width", implicitWidth))
  height: renderer.prop("height", null) === null ? implicitHeight : Number(renderer.prop("height", implicitHeight))
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

  onTargetIdChanged: {
    target = null
    Qt.callLater(resolveTarget)
  }
  onTargetChanged: {
    if (renderer.subscribed("target_change"))
      renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "target_change", {
        target: target ? targetId : null,
        resolved: target !== null
      })
  }
  Component.onCompleted: Qt.callLater(resolveTarget)

  Timer {
    interval: 16
    repeat: true
    running: proxy.targetId !== "" && proxy.target === null
    onTriggered: proxy.resolveTarget()
  }
}
