import QtQuick

Item {
  id: behaviorRoot
  property var renderer: null
  property var lastValue: undefined
  function option(name,fallback){var specification=renderer?renderer.prop("animation",{}):{};return specification&&specification[name]!==undefined?specification[name]:(renderer?renderer.prop(name,fallback):fallback)}
  readonly property var targetItem: renderer ? renderer.findRenderedItem(renderer.prop("target", "")) : null
  function synchronize(){if(!renderer||!targetItem||renderer.prop("enabled",true)===false)return;var property=String(renderer.prop("property","opacity"));var value=renderer.prop("value",targetItem[property]);if(lastValue===undefined){lastValue=targetItem[property]}nativeAnimation.target=targetItem;nativeAnimation.property=property;nativeAnimation.from=lastValue;nativeAnimation.to=value;lastValue=value;nativeAnimation.restart();renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"change",{property:property,value:value})}
  PropertyAnimation{id:nativeAnimation;duration:Number(behaviorRoot.option("duration",250));easing.type:renderer?renderer.easingType(behaviorRoot.option("easing","in_out_quad")):Easing.InOutQuad;onFinished:renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"finish",{})}
  Connections{target:renderer;function onNodeChanged(){behaviorRoot.synchronize()}}
  Component.onCompleted:synchronize()
}
