import QtQuick
import QtQml.Models

Item {
  id:proxyRoot;property var renderer:null;property alias model:nativeProxy
  function rebuild(){sourceModel.clear();var items=renderer?renderer.prop("items",[]):[];var requested=String(renderer?renderer.prop("filter",""):"");var field=String(renderer?renderer.prop("filter_field","value"):"value");var sensitive=renderer&&renderer.prop("filter_case_sensitive",false)===true;for(var i=0;i<items.length;i++){var item=items[i];var row=item!==null&&typeof item==="object"&&!Array.isArray(item)?item:{value:item};var value=String(row[field]===undefined?"":row[field]);if(requested!==""&&(sensitive?value.indexOf(requested)<0:value.toLowerCase().indexOf(requested.toLowerCase())<0))continue;sourceModel.append(row)}nativeProxy.invalidate();if(renderer)renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"change",{count:nativeProxy.rowCount()})}
  ListModel{id:sourceModel}
  SortFilterProxyModel{
    id:nativeProxy;model:sourceModel;dynamicSortFilter:!renderer||renderer.prop("dynamic",true)!==false;recursiveFiltering:renderer&&renderer.prop("recursive",false)===true;autoAcceptChildRows:renderer&&renderer.prop("auto_accept_children",false)===true
    filters:[]
    sorters:[StringSorter{enabled:renderer&&String(renderer.prop("sort_field",""))!=="";roleName:String(renderer?renderer.prop("sort_field","value"):"value");sortOrder:String(renderer?renderer.prop("sort_order","ascending"):"ascending")==="descending"?Qt.DescendingOrder:Qt.AscendingOrder;caseSensitivity:renderer&&renderer.prop("sort_case_sensitive",false)===true?Qt.CaseSensitive:Qt.CaseInsensitive}]
    onRowsInserted:function(parent,first,last){if(renderer)renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"count_change",{value:rowCount()})}
    onRowsRemoved:function(parent,first,last){if(renderer)renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"count_change",{value:rowCount()})}
  }
  Component.onCompleted:rebuild();Connections{target:renderer;function onNodeChanged(){proxyRoot.rebuild()}}
}
