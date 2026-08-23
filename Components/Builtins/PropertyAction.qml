import QtQuick

Item {
  id: actionRoot
  property var renderer: null
  property int handledRevision: -1
  readonly property var targetItem: renderer ? renderer.findRenderedItem(renderer.prop("target", "")) : null
  function run() { if (!renderer || !targetItem) return; var revision=Number(renderer.prop("revision",0));if(revision===handledRevision)return;handledRevision=revision;nativeAction.start() }
  PropertyAction { id: nativeAction; target: actionRoot.targetItem; property: String(renderer ? renderer.prop("property", "") : ""); value: renderer ? renderer.prop("value", null) : null; onFinished: { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "apply", { property: property, value: value }); renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "finish", {}) } }
  Component.onCompleted: run(); Connections { target: renderer; function onNodeChanged(){actionRoot.run()} }
}
