import QtQuick

Item {
  id: changeRoot
  property var renderer: null
  property int handledRevision: -1
  function apply(){if(!renderer)return;var revision=Number(renderer.prop("revision",0));if(revision===handledRevision)return;var target=renderer.findRenderedItem(renderer.prop("target",""));var parent=renderer.findRenderedItem(renderer.prop("parent",""));if(!target||!parent)return;handledRevision=revision;target.parent=parent;["x","y","width","height","scale","rotation"].forEach(function(key){var value=renderer.prop(key,null);if(value!==null)target[key]=value});renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"apply",{revision:revision,parent:renderer.prop("parent","")})}
  Connections{target:renderer;function onNodeChanged(){changeRoot.apply()}}
  Component.onCompleted:apply()
}
