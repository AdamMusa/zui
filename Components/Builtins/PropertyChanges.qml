import QtQuick

Item {
  id: changesRoot
  property var renderer: null
  property int handledRevision: -1
  function apply(){if(!renderer)return;var revision=Number(renderer.prop("revision",0));if(revision===handledRevision)return;var target=renderer.findRenderedItem(renderer.prop("target",""));if(!target)return;handledRevision=revision;var values=renderer.prop("properties",{});for(var key in values)if(target.hasOwnProperty(key))target[key]=values[key];renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"apply",{properties:values,revision:revision})}
  Connections{target:renderer;function onNodeChanged(){changesRoot.apply()}}
  Component.onCompleted:apply()
}
