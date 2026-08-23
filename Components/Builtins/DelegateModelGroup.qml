import QtQuick
import QtQml.Models

Item {
  id:groupRoot;property var renderer:null;property alias model:nativeDelegateModel;property alias group:nativeGroup
  function rebuild(){sourceModel.clear();var items=renderer?renderer.prop("items",[]):[];for(var i=0;i<items.length;i++){var item=items[i];sourceModel.append(item!==null&&typeof item==="object"&&!Array.isArray(item)?item:{value:item})}if(renderer)renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"count_change",{value:nativeGroup.count})}
  ListModel{id:sourceModel}
  DelegateModel{id:nativeDelegateModel;model:sourceModel;delegate:Item{required property int index} groups:[DelegateModelGroup{id:nativeGroup;name:String(renderer?renderer.prop("name","group"):"group");includeByDefault:renderer&&renderer.prop("include_by_default",false)===true;onCountChanged:if(renderer)renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"change",{value:count})}]}
  Component.onCompleted:rebuild();Connections{target:renderer;function onNodeChanged(){groupRoot.rebuild()}}
}
