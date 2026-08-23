import QtQuick
import QtMultimedia

Item {
  id:devicesRoot;property var renderer:null
  function payload(list){var values=[];for(var i=0;i<list.length;i++)values.push({id:String(list[i].id),description:list[i].description,default:list[i].isDefault});return values}
  function emitAll(){if(!renderer)return;var kind=String(renderer.prop("kind","all"));if(kind==="all"||kind==="video_inputs")renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"video_inputs",{values:payload(nativeDevices.videoInputs)});if(kind==="all"||kind==="audio_inputs")renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"audio_inputs",{values:payload(nativeDevices.audioInputs)});if(kind==="all"||kind==="audio_outputs")renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"audio_outputs",{values:payload(nativeDevices.audioOutputs)});renderer.bridge.sendEvent(renderer.surfaceName,renderer.controlId,"change",{kind:kind,revision:Number(renderer.prop("refresh_revision",0))})}
  MediaDevices{id:nativeDevices;onVideoInputsChanged:devicesRoot.emitAll();onAudioInputsChanged:devicesRoot.emitAll();onAudioOutputsChanged:devicesRoot.emitAll()}
  Component.onCompleted:emitAll();Connections{target:renderer;function onNodeChanged(){devicesRoot.emitAll()}}
}
