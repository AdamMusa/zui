import QtQuick

Item {
  id: controllerRoot
  property var renderer: null
  function option(name,fallback){var specification=renderer?renderer.prop("animation",{}):{};return specification&&specification[name]!==undefined?specification[name]:(renderer?renderer.prop(name,fallback):fallback)}
  readonly property var targetItem: renderer ? renderer.findRenderedItem(option("target", "")) : null
  NumberAnimation { id: controlledAnimation; target: controllerRoot.targetItem; property: String(controllerRoot.option("property", "opacity")); from: Number(controllerRoot.option("from", 0)); to: Number(controllerRoot.option("to", 1)); duration: Number(controllerRoot.option("duration", 1000)) }
  AnimationController { id: nativeController; animation: controlledAnimation; progress: Number(renderer ? renderer.prop("progress", 0) : 0); onProgressChanged: { renderer.bridge.sendEvent(renderer.surfaceName, renderer.controlId, "progress_change", { value: progress }); if(progress>=1)renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"finish",{}) } }
  Connections { target: renderer; function onNodeChanged(){nativeController.progress=Number(renderer.prop("progress",0));if(renderer.prop("reload",false)===true)nativeController.reload()} }
}
