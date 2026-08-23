import QtQuick

Item {
  id: changesRoot
  property var renderer: null
  property int handledRevision: -1
  function line(target,key){var value=renderer.prop("anchors",{})[key];if(value===undefined||value===null||String(value)==="")return undefined;var item=renderer.findRenderedItem(value);if(!item)return undefined;if(key==="left"||key==="right"||key==="horizontal_center")return key==="left"?item.left:(key==="right"?item.right:item.horizontalCenter);return key==="top"?item.top:(key==="bottom"?item.bottom:item.verticalCenter)}
  function apply(){if(!renderer)return;var revision=Number(renderer.prop("revision",0));if(revision===handledRevision)return;var target=renderer.findRenderedItem(renderer.prop("target",""));if(!target)return;handledRevision=revision;var anchors=renderer.prop("anchors",{});if(anchors.left!==undefined)target.anchors.left=line(target,"left");if(anchors.right!==undefined)target.anchors.right=line(target,"right");if(anchors.top!==undefined)target.anchors.top=line(target,"top");if(anchors.bottom!==undefined)target.anchors.bottom=line(target,"bottom");if(anchors.horizontal_center!==undefined)target.anchors.horizontalCenter=line(target,"horizontal_center");if(anchors.vertical_center!==undefined)target.anchors.verticalCenter=line(target,"vertical_center");var margins=renderer.prop("margins",{});for(var key in margins){var property=key.replace(/_([a-z])/g,function(_,letter){return letter.toUpperCase()});if(target.anchors.hasOwnProperty(property))target.anchors[property]=margins[key]}renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"apply",{revision:revision})}
  Connections{target:renderer;function onNodeChanged(){changesRoot.apply()}}
  Component.onCompleted:apply()
}
