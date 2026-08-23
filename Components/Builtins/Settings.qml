import QtQuick
import QtCore

Item {
  id:settingsRoot;property var renderer:null;property int handledSyncRevision:-1
  function load(){if(!renderer)return;var defaults=renderer.prop("values",{});var result={};for(var key in defaults)result[key]=nativeSettings.value(key,defaults[key]);renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"loaded",{values:result})}
  function synchronize(){if(!renderer)return;var values=renderer.prop("values",{});for(var key in values){var previous=nativeSettings.value(key);if(previous!==values[key]){nativeSettings.setValue(key,values[key]);renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"change",{key:key,value:values[key],previous:previous})}}var revision=Number(renderer.prop("sync_revision",0));if(revision!==handledSyncRevision){handledSyncRevision=revision;nativeSettings.sync();renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"synced",{revision:revision})}}
  Settings{id:nativeSettings;category:String(renderer?renderer.prop("category",""):"");location:renderer&&String(renderer.prop("file_name",""))!==""?renderer.assetUrl(renderer.prop("file_name","")):""}
  Component.onCompleted:{load();synchronize()}Connections{target:renderer;function onNodeChanged(){settingsRoot.synchronize()}}
}
