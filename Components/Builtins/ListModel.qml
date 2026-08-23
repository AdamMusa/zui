import QtQuick

Item {
  id:modelRoot;property var renderer:null;property alias model:nativeModel
  function rebuild(){nativeModel.clear();var items=renderer?renderer.prop("items",[]):[];for(var i=0;i<items.length;i++){var item=items[i];nativeModel.append(item!==null&&typeof item==="object"&&!Array.isArray(item)?item:{value:item})}if(renderer){renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"count_change",{value:nativeModel.count});renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"change",{count:nativeModel.count})}}
  ListModel{id:nativeModel}
  Component.onCompleted:rebuild();Connections{target:renderer;function onNodeChanged(){modelRoot.rebuild()}}
}
