import QtQuick

Item {
  id: stateRoot
  property var renderer: null
  property bool active: false
  property var previousValues: ({})
  readonly property var targetItem: renderer ? renderer.findRenderedItem(renderer.prop("target", "")) : null
  function applyProperties(values){if(!targetItem||!values||typeof values!=="object")return;for(var key in values)if(targetItem.hasOwnProperty(key))targetItem[key]=values[key]}
  function synchronize(){if(!renderer||!targetItem)return;var shouldEnter=renderer.prop("when",true)===true;if(shouldEnter===active)return;if(shouldEnter){previousValues={};var inherited=renderer.prop("extend",{});var values={};if(inherited&&typeof inherited==="object")for(var inheritedKey in inherited)values[inheritedKey]=inherited[inheritedKey];var requested=renderer.prop("properties",{});for(var requestedKey in requested)values[requestedKey]=requested[requestedKey];for(var key in values)if(targetItem.hasOwnProperty(key))previousValues[key]=targetItem[key];applyProperties(values);active=true;renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"enter",{name:renderer.prop("name","")})}else{if(renderer.prop("restore_entry_values",true)!==false)applyProperties(previousValues);active=false;renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"exit",{name:renderer.prop("name","")})}renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"change",{value:active,name:renderer.prop("name","")})}
  Connections{target:renderer;function onNodeChanged(){stateRoot.synchronize()}}
  Component.onCompleted:synchronize()
}
