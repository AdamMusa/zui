import QtQuick
import QtQml.Models

Item {
  id:modelRoot;property var renderer:null;property alias model:nativeDelegateModel
  function rebuild(){sourceModel.clear();var items=renderer?renderer.prop("items",[]):[];for(var i=0;i<items.length;i++){var item=items[i];sourceModel.append(item!==null&&typeof item==="object"&&!Array.isArray(item)?item:{value:item})}if(renderer)renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"count_change",{value:nativeDelegateModel.count})}
  ListModel{id:sourceModel}
  DelegateModel{id:nativeDelegateModel;model:sourceModel;filterOnGroup:String(renderer?renderer.prop("filter_group","items"):"items");delegate:Item{required property int index;property var sourceIndex:index}}
  Component.onCompleted:rebuild();Connections{target:renderer;function onNodeChanged(){modelRoot.rebuild()}}
}
