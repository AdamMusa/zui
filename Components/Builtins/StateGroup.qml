import QtQuick

Item {
  id: groupRoot
  property var renderer: null
  property string activeState: ""
  readonly property var targetItem: renderer ? renderer.findRenderedItem(renderer.prop("target", "")) : null
  function synchronize(){if(!renderer||!targetItem)return;var name=String(renderer.prop("current",""));var states=renderer.prop("states",[]);for(var index=0;index<states.length;index++){var state=states[index]||{};if(String(state.name)===name){var values=state.properties||{};for(var key in values)if(targetItem.hasOwnProperty(key))targetItem[key]=values[key];break}}if(name!==activeState){var old=activeState;activeState=name;renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"change",{value:name,previous:old})}}
  Connections{target:renderer;function onNodeChanged(){groupRoot.synchronize()}}
  Component.onCompleted:synchronize()
}
